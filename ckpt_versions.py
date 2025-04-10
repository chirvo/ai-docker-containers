import argparse
import logging
import json
import csv
from pathlib import Path
import torch
from safetensors import safe_open
from tabulate import tabulate

# --- Logging Setup ---
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

def get_model_info(file_path: Path):
    """
    Attempts to load a model file and extract the full metadata dictionary.
    Handles .ckpt, .checkpoint, and .safetensors files.
    Returns the metadata dictionary or {} on error or if no metadata found.
    """
    metadata_dict = {}
    try:
        if file_path.suffix == ".safetensors":
            # Use safe_open to read only metadata efficiently
            metadata = None
            # framework='pt' is common, device='cpu' avoids GPU use
            with safe_open(file_path, framework="pt", device="cpu") as f:
                metadata = f.metadata() # Gets the metadata dictionary

            if metadata:
                metadata_dict = metadata # Store the whole metadata dict
            else:
                logger.info(f"No metadata found in {file_path.name}")
            return metadata_dict

        elif file_path.suffix in [".ckpt", ".checkpoint"]:
            # PyTorch native loading
            checkpoint = torch.load(file_path, map_location="cpu")
            if isinstance(checkpoint, dict):
                # Return the whole checkpoint dictionary for .ckpt/.checkpoint
                # Note: This might include large tensors.
                metadata_dict = checkpoint
                return metadata_dict
            else:
                logger.warning(f"Checkpoint file {file_path.name} is not a dictionary.")
                return {}

        else:
            # Should not happen if called correctly, but good practice
            logger.warning(f"File type not recognized for {file_path.name}")
            return {}

    except Exception as e:
        logger.error(f"Error loading or processing file {file_path.name}: {e}")
        return {} # Return empty dict on error

def main():
    parser = argparse.ArgumentParser(
        description="Scan a directory for model files (.ckpt, .checkpoint, .safetensors), "
                    "extract metadata, and display or save it."
    )
    parser.add_argument('--directory', type=str, required=True,
                        help='The directory path to scan (non-recursive).')
    parser.add_argument('--output-json', type=str, default=None,
                        help='Save results as a JSON file.')
    parser.add_argument('--output-csv', type=str, default=None,
                        help='Save results as a CSV file.')
    parser.add_argument('--sort-by', type=str, default=None,
                        help='Sort results by a specific metadata key (e.g., "ss_sd_model_name").')
    parser.add_argument('--fields', type=str, default=None,
                        help='Comma-separated list of specific metadata fields to display/save.')

    args = parser.parse_args()

    directory = Path(args.directory)
    if not directory.is_dir():
        logger.error(f"Error: Directory not found or is not a directory: {args.directory}")
        return

    logger.info(f"Scanning directory: {args.directory}")
    print("-" * 30) # Keep visual separator

    model_files_metadata = []
    found_models = False

    for item in directory.iterdir(): # Non-recursive iteration
        if item.is_file() and item.suffix.lower() in [".ckpt", ".checkpoint", ".safetensors"]:
            found_models = True
            logger.info(f"Processing: {item.name}")
            metadata = get_model_info(item)
            if metadata:
                # Add filename to metadata for potential sorting/identification
                metadata['_filename'] = item.name
                model_files_metadata.append(metadata)
            else:
                logger.info(f"  No metadata extracted from {item.name}")
            print("-" * 10) # Separator for each file processed


    if not found_models:
        logger.info("No model files (.ckpt, .checkpoint, .safetensors) found in the directory.")
        return

    # --- Sorting ---
    if args.sort_by:
        sort_key = args.sort_by
        logger.info(f"Sorting results by metadata key: '{sort_key}'")
        # Sorts in place, handling missing keys gracefully (treating them as None/smallest)
        model_files_metadata.sort(key=lambda x: x.get(sort_key))

    # --- Field Selection ---
    selected_fields = None
    if args.fields:
        selected_fields = [f.strip() for f in args.fields.split(',')]
        # Ensure _filename is always included if specific fields are requested, for context
        if '_filename' not in selected_fields:
            selected_fields.insert(0, '_filename')
        logger.info(f"Selecting fields: {', '.join(selected_fields)}")

        # Filter the metadata list to only include selected fields
        filtered_metadata = []
        for meta in model_files_metadata:
            filtered_dict = {key: meta.get(key, 'N/A') for key in selected_fields}
            filtered_metadata.append(filtered_dict)
        model_files_metadata = filtered_metadata # Replace with filtered data


    # --- Output ---
    if args.output_json:
        logger.info(f"Saving results to JSON: {args.output_json}")
        try:
            with open(args.output_json, 'w', encoding='utf-8') as f:
                json.dump(model_files_metadata, f, indent=2, ensure_ascii=False)
            logger.info("Successfully saved JSON file.")
        except Exception as e:
            logger.error(f"Failed to save JSON file: {e}")

    elif args.output_csv:
        logger.info(f"Saving results to CSV: {args.output_csv}")
        if not model_files_metadata:
            logger.warning("No metadata to save to CSV.")
            return
        try:
            # Determine headers from the (potentially filtered) metadata
            headers = list(model_files_metadata[0].keys()) if model_files_metadata else []
            if selected_fields: # Use the order from --fields if provided
                headers = selected_fields

            with open(args.output_csv, 'w', newline='', encoding='utf-8') as f:
                writer = csv.DictWriter(f, fieldnames=headers)
                writer.writeheader()
                for meta_dict in model_files_metadata:
                    # Ensure all keys in headers are present, defaulting to 'N/A'
                    row = {header: meta_dict.get(header, 'N/A') for header in headers}
                    writer.writerow(row)
            logger.info("Successfully saved CSV file.")
        except Exception as e:
            logger.error(f"Failed to save CSV file: {e}")

    else:
        # Default: Print to console using tabulate
        logger.info("Displaying results in console:")
        if not model_files_metadata:
            logger.info("No metadata to display.")
            return

        if selected_fields:
            # Display only selected fields in a table
            headers = selected_fields
            table_data = [[item.get(header, 'N/A') for header in headers] for item in model_files_metadata]
            print(tabulate(table_data, headers=headers, tablefmt="fancy_grid", numalign="left", stralign="left"))
        else:
            # Display full metadata for each file, one by one (original style adapted)
            print("\n" + "=" * 30)
            print("Detailed Metadata per File:")
            print("=" * 30)
            # Re-iterate based on the collected/sorted data
            for meta_dict in model_files_metadata:
                filename = meta_dict.pop('_filename') # Remove filename temporarily for display
                print(f"\n--- File: {filename} ---")
                if meta_dict:
                    table_data = [[key, str(value)] for key, value in sorted(meta_dict.items())]
                    headers = ["Metadata Key", "Value"]
                    table = tabulate(table_data, headers=headers, tablefmt="fancy_grid", numalign="left", stralign="left")
                    print(f"  Metadata available ({len(meta_dict)} key-value pairs):")
                    indented_table = "\n".join(["  " + line for line in table.splitlines()])
                    print(indented_table)
                else:
                    print("  No other metadata available.")
                meta_dict['_filename'] = filename # Add back filename


if __name__ == "__main__":
    main()