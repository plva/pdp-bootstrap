#!/bin/zsh
zparseopts -E -D -- \
           -install-without-asking=INSTALL_WITHOUT_ASKING

# Check if not running on macOS
if [[ "$OSTYPE" != darwin* ]]; then
    echo "Not running on macOS. This script is intended only for macOS."
    exit 1
fi

NOT_INSTALLED=121
IS_INSTALLED=0

is_installed() {
    local formula=$1
    if ! command -v "${formula}" >/dev/null 2>&1; then
        return ${NOT_INSTALLED}
    else
        return ${IS_INSTALLED}
    fi
}

echo "Checking for Homebrew"
# Check if Homebrew is not installed
if ! is_installed brew; then
    echo "Homebrew is not installed. Installing Homebrew."
    read -q user_confirm
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/paulvasiu/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! is_installed nvim; then
    echo "nvim (neovim) is not installed. Install it using Homebrew? (y/n)"

    read -q user_confirm
    echo
    if [[ $user_confirm =~ ^[Yy]$ ]]; then
        echo "Installing nvim using Homebrew..."
        brew install nvim 
	"Installed nvim. Adding kickstart.nvim"
        git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
    else
        echo "Installation of nvim aborted by user."
        exit 1
    fi
else
    echo "nvim already installed"
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh is installed."
else
  echo "Oh My Zsh is not installed. Installing from githubusercontent.com/ohmyzsh."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

check_and_brew_install() {
    local formula=$1
    if is_installed "${formula}"; then
        echo "${formula} is installed."
    else
        echo "${formula} is not installed."
        brew_install "${formula}"
    fi 
}

ask_for_install () {
    local formula=$1
    
    if [[ -n "${INSTALL_WITHOUT_ASKING}" ]]; then
        echo "Installing ${formula} without asking."
        return 0
    else
        echo "what?"
    fi

    echo "Install ${formula} using Homebrew?"

    read -q user_confirm
    echo
    if [[ $user_confirm =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}



brew_install () {
   local formula=$1
   
   if ask_for_install "${formula}"; then
       echo "Installing ${formula} using Homebrew..."
       brew install "${formula}" 
   else
       echo "Installation of ${formula} using Homebrew aborted by user."
       exit 1
   fi
}

while read package
do
    check_and_brew_install "${package}"

done < "../config/brew-dependencies.list"

setup_custom_hosts() {
    echo "Adding custom hosts file. First backing up /etc/hosts"
    sudo mv /etc/hosts /etc/hosts.bak
    sudo cat ../hosts/default.hosts | sudo tee /etc/hosts
    sudo cat ../hosts/custom.hosts | sudo tee -a /etc/hosts
}

setup_custom_hosts
