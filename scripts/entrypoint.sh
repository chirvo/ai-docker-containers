#!/bin/bash
 
#################
# Script globals
GIT_URI="https://github.com/AUTOMATIC1111/stable-diffusion-webui"
COMMAND_EXTRA_PARAMS=""
COMMAND="python3 launch.py --listen --enable-insecure-extension-access"
PORT=7860
# generated envvars

_run_or_die () {
  $*
  if [ $? -ne 0 ]; then
    echo "Error: command -= $* =- failed"
    exit 1
  fi
}

_get_dest_dir () {
  local BASE_DIR=$(pwd)
  if [ "$BASE_DIR" == "/" ]; then
    BASE_DIR=""
  fi
  # returns DEST_DIR
  echo "$BASE_DIR/$(basename $GIT_URI .git)"
}

_clone_or_rebase_repo () {
  local DEST_DIR=$(_get_dest_dir)
  if [ -d "$DEST_DIR" ]; then
    echo "Directory $DEST_DIR exists. Pulling changes."
    _run_or_die cd $DEST_DIR
    _run_or_die git pull
    _run_or_die cd -
  else
    _run_or_die git clone $GIT_URI $DEST_DIR
  fi

  cd $DEST_DIR
  git config --global --add safe.directory '*'
  cd -
}

_prepare_venv () {
  _run_or_die python3 -m venv venv --system-site-packages
  source ./venv/bin/activate
}

_install_requirements () {
  local DEST_DIR=$(_get_dest_dir)
  _run_or_die cd $DEST_DIR
  if [ ! -f "requirements.txt" ]; then
    echo "Error: 'requirements.txt does not exist.'"
    exit 1
  fi
  # cat requirements.txt | grep -vw torch > ./_requirements.txt
  # mv ./_requirements.txt ./requirements.txt
  _run_or_die pip3 install -r requirements.txt
  cd -
}

run () {
  local DEST_DIR=$(_get_dest_dir)

  echo "0. Cloning $GIT_URI into $DEST_DIR"
  _clone_or_rebase_repo

  echo "1. Preparing venv"
  _prepare_venv

  echo "2. Installing requirements"
  _install_requirements

  echo "3. Running the damn thing"

  # run the command
  cd $DEST_DIR
  /bin/sh -c "$COMMAND $COMMAND_EXTRA_PARAMS"
  cd -
}

case "$1" in
  a1111) echo "Running AUTOMATIC1111"
    GIT_URI="https://github.com/AUTOMATIC1111/stable-diffusion-webui"
    COMMAND_EXTRA_PARAMS=""
    COMMAND="python3 launch.py --listen --enable-insecure-extension-access"
    PORT=7860
  ;;
  comfy) echo "Running ComfyUI"
    GIT_URI="https://github.com/comfyanonymous/ComfyUI.git"
    COMMAND_EXTRA_PARAMS=""
    COMMAND="python3 main.py --listen --enable-insecure-extension-access --precision full --no-half --opt-sub-quad-attention"
    PORT=8188
  ;;
  bash) echo "Running /bin/bash"
    /bin/bash
    exit 0
  ;;
  *) echo "'$1' is not a valid option."
    exit 1
  ;;
esac
echo "run $1"
run $1
exit 0
