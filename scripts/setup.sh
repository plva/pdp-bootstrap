#!/bin/zsh

# Setup logging
LOG_DIR="$HOME/.pdp/logs"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

error() {
    log "ERROR" "$1"
    exit 1
}

info() {
    log "INFO" "$1"
}

# Function to run commands with error handling and output logging
run_with_error_handling() {
    local cmd="$1"
    local description="$2"
    
    log "INFO" "Running: $description"
    log "INFO" "Command: $cmd"
    
    # Run the command and capture both stdout and stderr
    local output
    if ! output=$(eval "$cmd" 2>&1); then
        log "ERROR" "Failed: $description"
        log "ERROR" "Command output: $output"
        exit 1
    fi
    
    # Log the command output if it's not empty
    if [ -n "$output" ]; then
        log "INFO" "Command output: $output"
    fi
}

zparseopts -E -D -- \
           -install-without-asking=INSTALL_WITHOUT_ASKING \
           -force-update-all=FORCE_UPDATE_ALL

info "Starting setup script"

# Check if not running on macOS
if [[ "$OSTYPE" != darwin* ]]; then
    error "Not running on macOS. This script is intended only for macOS."
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

info "Checking for Homebrew"
# Check if Homebrew is not installed
if ! is_installed brew; then
    info "Homebrew is not installed. Installing Homebrew."
    read -q user_confirm
    run_with_error_handling \
        '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
        "Failed to install Homebrew"
    
    run_with_error_handling \
        'echo >> /Users/paul/.zprofile && echo "eval \"$(/opt/homebrew/bin/brew shellenv)\"" >> /Users/paul/.zprofile' \
        "Failed to update .zprofile with Homebrew path"
    
    eval "$(/opt/homebrew/bin/brew shellenv)"
    info "Homebrew installed successfully"
fi

if ! is_installed nvim; then
    info "nvim (neovim) is not installed. Install it using Homebrew? (y/n)"

    read -q user_confirm
    echo
    if [[ $user_confirm =~ ^[Yy]$ ]]; then
        info "Installing nvim using Homebrew..."
        run_with_error_handling \
            'brew install nvim' \
            "Failed to install nvim"
        
        info "Installed nvim. Adding kickstart.nvim"
        run_with_error_handling \
            'git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim' \
            "Failed to clone kickstart.nvim"
    else
        error "Installation of nvim aborted by user."
    fi
else
    info "nvim already installed"
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Oh My Zsh is installed."
else
    info "Oh My Zsh is not installed. Installing from githubusercontent.com/ohmyzsh."
    run_with_error_handling \
        'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' \
        "Failed to install Oh My Zsh"
fi

check_and_brew_install() {
    local formula=$1
    if is_installed_with_brew "${formula}" || is_installed "${formula}"; then
        info "${formula} is installed."
    else
        info "${formula} is not installed."
        brew_install "${formula}"
    fi 
}

ask_for_install () {
    local formula=$1
    local package_manager=$2
    
    if [[ -n "${INSTALL_WITHOUT_ASKING}" ]]; then
        info "Installing ${formula} without asking."
        return 0
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
       info "Installing ${formula} using Homebrew..."
       run_with_error_handling \
           "brew install ${formula}" \
           "Failed to install ${formula} using Homebrew"
   else
       error "Installation of ${formula} using Homebrew aborted by user."
   fi
}

info "Installing Homebrew dependencies"
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
    # First ensure Node.js is installed
    if ! is_installed node; then
        echo "Node.js is required for npm packages but is not installed. Installing Node.js..."
        brew install node
    fi

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
        python3 -m pip install --upgrade pip --user
    else
        echo "Skipping pip upgrade, to force use '--force-update-all' flag if needed."
        return 0
    fi
}

upgrade_pip
setup_tmux_conf() {
    info "Setting up tmux configuration"
    echo "we are in $(pwd)"
    if [ -f ~/.tmux.conf ]; then
        info "Backing up ~/.tmux.conf"
        run_with_error_handling \
            'cp ~/.tmux.conf ~/.tmux.conf.bak' \
            "Failed to backup ~/.tmux.conf"
    fi
    info "Copying config/.tmux.conf to ~/.tmux.conf"
    run_with_error_handling \
        'cp ../config/tmux.conf ~/.tmux.conf' \
        "Failed to copy tmux configuration"
}

setup_tmux_conf
setup_custom_hosts

setup_tpm() {
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        log "INFO" "Setting up tmux package manager (tpm)."
        run_with_error_handling "git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm" "install tmux package manager"
    else
        log "INFO" "tmux package manager (tpm) is already installed."
    fi
}

setup_tpm

# using pip3
setup_pip_dependencies() {
    # Ensure pipx is installed
    if ! is_installed pipx; then
        info "pipx is not installed. Installing pipx via Homebrew..."
        run_with_error_handling \
            'brew install pipx' \
            "Failed to install pipx"
    fi
    
    log "INFO" "Installing Python CLI tools via pipx"
    run_with_error_handling "pipx install gita" "install gita"
    run_with_error_handling "pipx install mitmproxy" "install mitmproxy"
    
    run_with_error_handling \
        'pipx ensurepath' \
        "Failed to ensure pipx PATH"
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
        info "zsh-autocomplete is already installed"
    else
        info "setting up zsh-autocomplete"
        run_with_error_handling \
            'mkdir -p ~/repos && git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ~/repos/zsh-autocomplete' \
            "Failed to install zsh-autocomplete"
    fi
}
check_and_install_zsh_autocomplete

info "Setup completed successfully"

