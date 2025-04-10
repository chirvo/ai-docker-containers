import os
import argparse
import torch
from safetensors import safe_open
from tabulate import tabulate # Import tabulate

def get_model_info(file_path):
    """
    Attempts to load a model file and extract the full metadata dictionary.
    Handles .ckpt, .checkpoint, and .safetensors files.
    Returns the metadata dictionary or {} on error or if no metadata found.
    """
    metadata_dict = {}
    try:
        if file_path.endswith(".safetensors"):
            # Use safe_open to read only metadata efficiently
            metadata = None
            with safe_open(file_path, framework="pt", device="cpu") as f: # framework='pt' is common, device='cpu' avoids GPU use
                metadata = f.metadata() # Gets the metadata dictionary

            if metadata:
                metadata_dict = metadata # Store the whole metadata dict
            elif not metadata:
                print(f"  Info: No metadata found in {os.path.basename(file_path)}")
            # Return regardless of whether version was found, as long as metadata was read
            # Return metadata dictionary
            return metadata_dict

        elif file_path.endswith((".ckpt", ".checkpoint")):
            # PyTorch native loading
            checkpoint = torch.load(file_path, map_location="cpu")
            # Common places for version info (heuristics based on common practices)
            if isinstance(checkpoint, dict):
                # We will return the whole checkpoint dictionary for .ckpt
                # Note: This might include large tensors if not structured carefully in the checkpoint.
                # For simplicity now, we return the whole dict. Consider filtering later if needed.
                metadata_dict = checkpoint
                # Version finding logic was removed previously
                return metadata_dict # Return the whole checkpoint dict
            else:
                print(f"  Warning: Checkpoint file {os.path.basename(file_path)} is not a dictionary.")
                return {} # Return empty dict

        else:
            # Should not happen if called correctly, but good practice
            print(f"  Warning: File type not recognized for {os.path.basename(file_path)}")
            return {}

    except Exception as e:
        print(f"  Error loading or processing file {os.path.basename(file_path)}: {e}")
        return {} # Return empty dict on error

def main():
    parser = argparse.ArgumentParser(description="Scan a directory for model files (.ckpt, .checkpoint, .safetensors) and print their metadata key-value pairs.")
    parser.add_argument("directory", help="The directory path to scan.")
    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"Error: Directory not found: {args.directory}")
        return

    print(f"Scanning directory: {args.directory}")
    print("-" * 30)

    found_models = False
    for filename in os.listdir(args.directory):
        if filename.lower().endswith((".ckpt", ".checkpoint", ".safetensors")):
            found_models = True
            file_path = os.path.join(args.directory, filename)
            if os.path.isfile(file_path):
                print(f"Processing: {filename}")
                metadata_dict = get_model_info(file_path) # Get the metadata dict

                # Version printing removed
                # Then print metadata key-value pairs using tabulate
                if metadata_dict:
                    # Prepare data for tabulate: list of [key, value_string] lists
                    # Convert values to string for display, handle potential complex objects simply
                    table_data = [[key, str(value)] for key, value in sorted(metadata_dict.items())]
                    # Generate table with headers
                    headers = ["Metadata Key", "Value"]
                    table = tabulate(table_data, headers=headers, tablefmt="fancy_grid", numalign="left", stralign="left")
                    print(f"  Metadata available ({len(metadata_dict)} key-value pairs):")
                    # Indent the table slightly for better visual structure
                    indented_table = "\n".join(["  " + line for line in table.splitlines()])
                    print(indented_table)
                else:
                    print(f"  No metadata available")

                print("-" * 10) # Separator for each file

    if not found_models:
        print("No model files (.ckpt, .checkpoint, .safetensors) found in the directory.")

if __name__ == "__main__":
    main()