#!/bin/bash

set -e

temp="$(mktemp -d)"

echo $temp

cd $temp

echo "temporarily downloading golang to compile argon and isotope..."

ARCHITECTURE=$(uname -m)

if [ $ARCHITECTURE = "x86_64" ]; then
    ARCHITECTURE="amd64"
fi
if [ $ARCHITECTURE = "aarch64" ]; then
    ARCHITECTURE="arm64"
fi

# Get the operating system
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Specify the Go version you want to install
GO_VERSION="1.22.0"  # Change this to your desired Go version

# Specify the folder where you want to install Go
INSTALLATION_PATH="./go"

mkdir -p "${INSTALLATION_PATH}"

URL="https://dl.google.com/go/go${GO_VERSION}.${OS}-${ARCHITECTURE}.tar.gz"

echo $URL

# Download the Go archive
curl -o go.tar.gz $URL

tar -C "${INSTALLATION_PATH}" -xzf go.tar.gz


echo "downloading argon and isotope..."

mkdir output

git clone https://github.com/open-argon/argon-v3

git clone https://github.com/open-argon/isotope

cd argon-v3

echo "
building argon..."
../go/go/bin/go build -trimpath -ldflags="-s -w" -o bin/argon ./src
echo "built argon
"

cd ../isotope

echo "
building isotope..."
../go/go/bin/go build -trimpath -ldflags="-s -w" -o ./bin/isotope ./src
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
if [ $SHELL = "/bin/bash" ]; then
    bash_config=~/.bashrc
    if ! path_exists "export PATH=\$PATH:$save_path" "$bash_config"; then
        echo 'export PATH=$PATH:'"$save_path" >> "$bash_config"
        echo "Path added to Bash configuration."
    else
        echo "Path already exists in Bash configuration."
    fi
fi

# Check if Zsh is the default shell
if [ $SHELL = "/bin/zsh" ]; then
    zsh_config=~/.zshrc
    if ! path_exists "export PATH=\$PATH:$save_path" "$zsh_config"; then
        echo 'export PATH=$PATH:'"$save_path" >> "$zsh_config"
        echo "Path added to Zsh configuration."
    else
        echo "Path already exists in Zsh configuration."
    fi
fi

# Check if Fish is the default shell
if [ $SHELL = "/bin/fish" ]; then
    fish_config=~/.config/fish/config.fish
    if ! path_exists "set --export PATH \$PATH $save_path" "$fish_config"; then
        echo 'set --export PATH $PATH '"$save_path" >> "$fish_config"
        echo "Path added to Fish configuration."
    else
        echo "Path already exists in Fish configuration."
    fi
fi

# Check if Tcsh is the default shell
if [ $SHELL = "/bin/tcsh" ]; then
    tcsh_config=~/.tcshrc
    if ! path_exists "setenv PATH \$PATH:$save_path" "$tcsh_config"; then
        echo 'setenv PATH $PATH:'"$save_path" >> "$tcsh_config"
        echo "Path added to Tcsh configuration."
    else
        echo "Path already exists in Tcsh configuration."
    fi
fi
