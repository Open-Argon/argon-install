#!/bin/bash

set -e

temp="$(mktemp -d)"

echo $temp

cd $temp

echo "temporarily downloading golang to compile argon and isotope..."

if ! command -v curl &> /dev/null; then
    echo "Error: curl is not installed. Please install curl before running this script. For example, you can install curl by running 'sudo apt install curl' on Debian based distros."
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install git before running this script. For example, you can install git by running 'sudo apt install git' on Debian based distros."
    exit 1
fi

ARCHITECTURE=$(uname -m)

if [ $ARCHITECTURE = "x86_64" ]; then
    ARCHITECTURE="amd64"
fi

# Get the operating system
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Specify the Go version you want to install
GO_VERSION="1.22.0"  # Change this to your desired Go version

# Specify the folder where you want to install Go
INSTALLATION_PATH=$(realpath "./go")

mkdir -p "${INSTALLATION_PATH}"

URL="https://dl.google.com/go/go${GO_VERSION}.${OS}-${ARCHITECTURE}.tar.gz"

echo $URL

# Download the Go archive
curl -o go.tar.gz $URL

tar -C "${INSTALLATION_PATH}" -xzf go.tar.gz

temp_directory=$INSTALLATION_PATH/go/bin

original_path=$PATH

export PATH=$PATH:$temp_directory


echo "downloading argon and isotope..."

mkdir output

git clone https://github.com/open-argon/argon-v3

git clone https://github.com/open-argon/isotope

cd argon-v3

echo "
building argon..."
sh ./build
echo "built argon
"

cd ../isotope

echo "
building isotope..."
sh ./build
echo "built isotope
"

cd ..

mv ./argon-v3/bin/* ./output
mv ./isotope/bin/* ./output

save_path="$(realpath ~/.argon)"

mkdir -p $save_path

mv ./output/* $save_path

echo "installed argon and isotope to $save_path
"

echo "cleaning up..."
cd ..
rm -r -f $temp

# Function to check if a path is already in the configuration file
path_exists() {
    grep -qFx "$1" "$2"
}

# Check if Bash is the default shell
if [ -n "$BASH_VERSION" ]; then
    bash_config=~/.bashrc
    if ! path_exists "export PATH=\$PATH:$save_path" "$bash_config"; then
        echo 'export PATH=$PATH:'"$save_path" >> "$bash_config"
        source "$bash_config"
        echo "Path added to Bash configuration."
    else
        echo "Path already exists in Bash configuration."
    fi
fi

# Check if Zsh is the default shell
if [ -n "$ZSH_VERSION" ]; then
    zsh_config=~/.zshrc
    if ! path_exists "export PATH=\$PATH:$save_path" "$zsh_config"; then
        echo 'export PATH=$PATH:'"$save_path" >> "$zsh_config"
        source "$zsh_config"
        echo "Path added to Zsh configuration."
    else
        echo "Path already exists in Zsh configuration."
    fi
fi

# Check if Fish is the default shell
if command -v fish >/dev/null 2>&1; then
    fish_config=~/.config/fish/config.fish
    if ! path_exists "set --export PATH \$PATH $save_path" "$fish_config"; then
        echo 'set --export PATH $PATH '"$save_path" >> "$fish_config"
        source "$fish_config"
        echo "Path added to Fish configuration."
    else
        echo "Path already exists in Fish configuration."
    fi
fi

# Check if Tcsh is the default shell
if [ -n "$shell" ] && [ "$(basename $SHELL)" = "tcsh" ]; then
    tcsh_config=~/.tcshrc
    if ! path_exists "setenv PATH \$PATH:$save_path" "$tcsh_config"; then
        echo 'setenv PATH $PATH:'"$save_path" >> "$tcsh_config"
        source "$tcsh_config"
        echo "Path added to Tcsh configuration."
    else
        echo "Path already exists in Tcsh configuration."
    fi
fi
