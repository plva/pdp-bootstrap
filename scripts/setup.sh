#!/bin/zsh
zparseopts -E -D -- \
           -install-without-asking=INSTALL_WITHOUT_ASKING \
           -force-update-all=FORCE_UPDATE_ALL


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

is_installed_with_brew() {
    local formula=$1
    local cache_file="/tmp/memoize_brew_install.cache"

    if [ ! -e "${cache_file}" ]; then
        brew list > "${cache_file}"
    fi

    if ! cat "${cache_file}" | grep -E "^${formula}$">/dev/null 2>&1; then
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
    if is_installed_with_brew "${formula}" || is_installed "${formula}"; then
        echo "${formula} is installed."
    else
        echo "${formula} is not installed."
        brew_install "${formula}"
    fi 
}

ask_for_install () {
    local formula=$1
    local package_manager=$2
    
    if [[ -n "${INSTALL_WITHOUT_ASKING}" ]]; then
        echo "Installing ${formula} without asking."
        return 0
    else
        echo "what?"
    fi

    echo "Install ${formula} using ${package_manager}?"

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
   
   if ask_for_install "${formula}" "homebrew"; then
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

npm_global_install() {
    local package=$1

    if ask_for_install "${package}" "npm"; then
        echo "Installing ${package} globally using npm..."
        npm install -g "${package}"
    else
        echo "Installation of ${package} using npm aborted by user."
        exit 1
    fi
}

check_and_npm_global_install() {
    local package=$1

    if npm list -g "${package}" >/dev/null 2>&1; then
        echo "${package} is already globally installed."
    else
        echo "${package} is not globally installed."
        npm_global_install "${package}"
    fi
}

install_global_npm_packages() {
    while read package
    do
        check_and_npm_global_install "${package}"
    done < "../config/npm-global-dependencies.list"
}

install_global_npm_packages

check_for_zoxide() {
    if ! is_installed zoxide; then
        echo "zoxide is not installed, skipping init"
    # else
    #     echo "running zoxide init"
    #     eval "$(zoxide init zsh)"
    fi
}
check_for_zoxide

setup_custom_hosts() {
    if [[ -n "${FORCE_UPDATE_ALL}" ]]; then
        echo "Adding custom hosts file. First backing up /etc/hosts"
    else
        echo "Skipping hosts file install, use '--force-update-all' flag if needed."
        return 0
    fi
    sudo mv /etc/hosts /etc/hosts.bak
    sudo cat ../hosts/default.hosts | sudo tee /etc/hosts
    sudo cat ../hosts/custom.hosts | sudo tee -a /etc/hosts
}

upgrade_pip() {
    if [[ -n "${FORCE_UPDATE_ALL}" ]]; then
        echo "Upgrading pip"
    else
        echo "Skipping pip upgrade, to force use '--force-update-all' flag if needed."
        return 0
    fi
    python3 -m pip install --upgrade pip
}


upgrade_pip
setup_tmux_conf() {
    echo "we are in $(pwd)"
    echo "Backing up ~/.tmux.conf"
    cp ~/.tmux.conf ~/.tmux.conf.bak
    echo "Copying config/.tmux.conf to ~/.tmux.conf"
    cp ../config/tmux.conf ~/.tmux.conf
}

satup_tmux_conf
setup_custom_hosts

setup_tpm() {
    local TPM_DIR="~/.tmux/plugins/tpm"
    if [[ -d "${TPM_DIR}" ]]; then
        echo "tpm already installed."
        return 0
    else
        echo "no tpm dir"
    fi

    echo "Setting up tmux package manager (tpm)."
    echo "creating '${TPM_DIR}'"
#    git clone https://github.com/tmux-plugins/tpm "${TPM_DIR}"
}

setup_tpm

# using pip3
setup_pip_dependencies() {
    pip3 install -U gita
    # this fails for some reason
    # pip3 install --upgrade lookatme
    pip install mitmproxy
}
setup_pip_dependencies

setup_tmuxinator_completions() {
    local TMUXINATOR_FUNCTIONS_DIR="/usr/local/share/zsh/site-functions"
    if [[ -n "${FORCE_UPDATE_ALL}" ]]; then
        echo "setting up tmuxinator completions in ${TMUXINATOR_FUNCTIONS_DIR}"
    else
        echo "Skipping tmuxinator completions upgrade, to force use '--force-update-all' flag if needed."
        return 0
    fi
    sudo mkdir -p "${TMUXINATOR_FUNCTIONS_DIR}"
    sudo wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.zsh -O "${TMUXINATOR_FUNCTIONS_DIR}/_tmuxinator"
}
setup_tmuxinator_completions


check_and_install_zsh_autocomplete() {
    if [[ -d ~/repos/zsh-autocomplete ]]; then
        echo "zsh-autocomplete is already installed"
    else
        echo "setting up zsh-autocomplete"
        git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ~/repos
    fi
}
check_and_install_zsh_autocomplete

