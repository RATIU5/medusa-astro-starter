#!/bin/bash

# Check if running on macOS
if [ "$(uname)" != "Darwin" ]; then
    echo "Error: This script is intended to run only on macOS."
    echo "Current OS: $(uname)"
    exit 1
fi

# Get project name from arguments
if [ -z "$1" ]; then
    echo "Please provide a project name."
    exit 1
fi

# Set project name variable
PROJECT_NAME=$1

# Check required software
required_software=(
    "node:20.16.0:node --version:node@20"
    "docker:26.1.0:extract_docker_version:docker"
)

# Array to store software that needs to be installed
to_install=()

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to extract docker version
extract_docker_version() {
    docker --version | sed -n 's/^Docker version \([0-9.]*\),.*/\1/p'
}

# Function to compare versions
version_compare() {
    # Remove 'v' prefix and any characters after the version number
    ver1=$(echo "$1" | sed -E 's/^[vV]?//; s/[^0-9.].*$//')
    ver2=$(echo "$2" | sed -E 's/^[vV]?//; s/[^0-9.].*$//')

    IFS='.' read -ra VER1 <<< "$ver1"
    IFS='.' read -ra VER2 <<< "$ver2"

    for i in "${!VER1[@]}"; do
        if [[ -z ${VER2[i]} ]]; then
            VER2[i]=0
        fi
        if ((10#${VER1[i]} > 10#${VER2[i]})); then
            return 1
        fi
        if ((10#${VER1[i]} < 10#${VER2[i]})); then
            return 2
        fi
    done

    if ((${#VER1[@]} < ${#VER2[@]})); then
        return 2
    else
        return 0
    fi
}

# Function to check software version
check_version() {
    local software=$1
    local required_version=$2
    local version_command=$3
    local brew_package=$4

    echo "Checking $software version..."

    if ! command -v $software &> /dev/null; then
        echo "$software is not installed."
        to_install+=("$brew_package")
        return 1
    fi

    local current_version
    if [ "$software" = "docker" ]; then
        current_version=$(extract_docker_version)
    else
        current_version=$($version_command)
    fi

    version_compare "$current_version" "$required_version"
    case $? in
        0) echo "$software version $current_version meets the requirement." ;;
        1) echo "$software version $current_version meets the requirement." ;;
        2) echo "$software version $current_version does not meet the minimum requirement of $required_version."
           to_install+=("$brew_package")
           return 1 ;;
    esac
}

# Function to install Homebrew
install_homebrew() {
    echo "Homebrew is not installed. Would you like to install it? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Determine shell and config file
        local shell_name=$(basename "$SHELL")
        local config_file=""
        case "$shell_name" in
            bash)
                config_file="$HOME/.bash_profile"
                ;;
            zsh)
                # Check for custom Zsh config locations
                if [[ -n "$ZDOTDIR" ]]; then
                    config_file="$ZDOTDIR/.zshrc"
                elif [[ -f "$HOME/.config/zsh/.zshrc" ]]; then
                    config_file="$HOME/.config/zsh/.zshrc"
                elif [[ -f "$HOME/.zshrc" ]]; then
                    config_file="$HOME/.zshrc"
                else
                    config_file="$HOME/.zshrc"
                    touch "$config_file"
                fi
                ;;
            fish)
                config_file="$HOME/.config/fish/config.fish"
                ;;
            *)
                echo "Unsupported shell: $shell_name. Please add Homebrew to your PATH manually."
                return 1
                ;;
        esac

        # Add Homebrew to PATH
        local homebrew_path=""
        if [[ $(uname -m) == "arm64" ]]; then
            homebrew_path="/opt/homebrew"
        else
            homebrew_path="/usr/local"
        fi

        if [[ "$shell_name" == "fish" ]]; then
            echo "set -gx PATH $homebrew_path/bin \$PATH" >> "$config_file"
            # Note: Sourcing for fish shell would require a different approach
        else
            echo "export PATH=$homebrew_path/bin:\$PATH" >> "$config_file"
            # Source the updated config file
            source "$config_file"
        fi

        echo "Homebrew has been installed and added to your PATH in $config_file"
        echo "The configuration has been sourced for this session."
    else
        echo "Homebrew is required to proceed. Exiting."
        exit 1
    fi
}

# Function to ensure Homebrew is in PATH
ensure_homebrew_in_path() {
    if ! command -v brew &> /dev/null; then
        echo "Homebrew is not in PATH. Attempting to add it..."
        local homebrew_path=""
        if [[ $(uname -m) == "arm64" ]]; then
            homebrew_path="/opt/homebrew"
        else
            homebrew_path="/usr/local"
        fi
        export PATH="$homebrew_path/bin:$PATH"
    fi
}

# Check all required software
for software in "${required_software[@]}"; do
    IFS=':' read -r name version command package <<< "$software"
    check_version "$name" "$version" "$command" "$package"
done

is_docker_installed=false

# Install required software
if [ ${#to_install[@]} -gt 0 ]; then
    
    # Install Homebrew if not present
    if ! command -v brew &> /dev/null; then
        install_homebrew
    fi

    # Ensure Homebrew is in PATH
    ensure_homebrew_in_path

    # Now you can use Homebrew
    if command -v brew &> /dev/null; then
        
        for package in "${to_install[@]}"; do
            echo "Would you like to install or update $package? (y/N)"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                echo "Installing $package..."
                if [ "$package" = "docker" ]; then
                    brew install --cask docker
                    is_docker_installed=true
                else
                    brew install "$package"
                fi
                if [ "$package" = "node@20" ]; then
                    node_installed=true
                elif [ "$package" = "docker" ]; then
                    is_docker_installed=true
                fi
            else
                echo "Skipping installation of $package. This may affect the functionality of the project."
                if [ "$package" = "node@20" ]; then
                    node_installed=false
                elif [ "$package" = "docker" ]; then
                    is_docker_installed=false
                fi
            fi
        done
    else
        echo "Failed to add Homebrew to PATH. Please restart your terminal and run the script again."
        exit 1
    fi
else
    # If node was already installed, set node_installed to true
    if command -v node &> /dev/null; then
        node_installed=true
    fi
    # If docker was already installed, set is_docker_installed to true
    if command -v docker &> /dev/null; then
        is_docker_installed=true
    fi
fi

if ! eval $is_docker_installed; then
    echo "Docker is required to proceed. Exiting."
    exit 1
fi

node_and_pnpm_installed=false

# Check for pnpm only if node is installed
if $node_installed; then
    echo "Checking pnpm version..."
    if ! command -v pnpm &> /dev/null; then
        echo "pnpm is not installed."
        echo "Would you like to install pnpm globally using npm? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo "Installing pnpm globally..."
            npm install -g pnpm
            node_and_pnpm_installed=true
        else
            echo "Skipping installation of pnpm. This may affect the functionality of the project."
        fi
    else
        pnpm_version=$(pnpm --version)
        required_pnpm_version="9.5.0"
        version_compare "$pnpm_version" "$required_pnpm_version"
        case $? in
            0) echo "pnpm version $pnpm_version meets the requirement."
               node_and_pnpm_installed=true ;;  # Set true if pnpm is already compliant
            1) echo "pnpm version $pnpm_version meets the requirement."
               node_and_pnpm_installed=true ;;  # Set true if pnpm is already compliant
            2) echo "pnpm version $pnpm_version does not meet the minimum requirement of $required_pnpm_version."
               echo "Would you like to update pnpm? (y/N)"
               read -r response
               if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                    echo "Updating pnpm..."
                    npm install -g pnpm@latest
                    node_and_pnpm_installed=true
               else
                   echo "Skipping update of pnpm. This may affect the functionality of the project."
               fi ;;
        esac
    fi
else
    echo "Node.js is not installed. Please install the latest version of Node.js."
fi

if ! eval $node_and_pnpm_installed; then
    echo "Node.js and pnpm are required to proceed. Exiting."
    exit 1
fi

echo "All required software is installed."

# Determine if the project directory already exists
if [ -d "$PROJECT_NAME" ]; then
    echo "Directory $PROJECT_NAME already exists. Please choose a different project name."
    exit 1
fi

# Clone the repository template to a new directory with the project name
git clone --branch v3 https://github.com/RATIU5/medusa-astro-starter.git "$PROJECT_NAME"


# Change to the project directory
cd "$PROJECT_NAME" || exit

# Remove the .git directory
rm -rf .git

# Remove the install script
rm install.sh

# Copy the .env.example file to .env
cp .env.example .env

# Iterate through all files and replace all instances of "changemename" with the project name
find . -type f -exec sed -i '' -e "s/changemename/$PROJECT_NAME/g" {} \;

# Initialize a new git repository
git init

# Install the database with Docker Compose
docker compose up -d

# Change directory to the packages directory
cd packages || exit

# Create a new Astro project
pnpm create astro@latest storefront --no-git --skip-houston --install --typescript strictest --template minimal

pnpm dlx create-medusa-app@latest --no-browser --db-url postgres://postgres:postgres@localhost:5432/medusa --directory-path medusa
