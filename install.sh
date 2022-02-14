#!/bin/sh

SYSTEM_ETC="${ETC:-/etc}"
SYSTEM_HOME="${HOME:-/home/`whoami`}"

PACKAGE_ROOT="`dirname $0`"
PACKAGE_ETC="${PACKAGE_ROOT}/etc"
PACKAGE_HOME="${PACKAGE_ROOT}/home/hyunh"

# arg 1: string: file to rename, cannot be empty
# arg 2: string: suffix, defaults to `.old`
# arg 3:   bool: copy instead of move? defaults to move
backup_and_report() {
    1="${1?}"
    2="${2:-.old}"
    3="${3:-false}"

    if [ "${3}" = "true" ]; then
        cp "${1}" "${1}${2}"
    else
        mv "${1}" "${1}${2}"
    fi

    echo "* ${1} -> ${1}${2}"
}

# arg 1: string: source dir, cannot be empty
# arg 2: string: destination dir, cannot be empty
# arg 3: string: target relative path, cannot be empty
# arg 4:   bool: copy instead of symlinking? defaults to symlinking
install_and_report() {
    1="${1?}"
    2="${2?}"
    3="${3?}"
    4="${4:-false}"

    if [ "${4}" = "true" ]; then
        cp "${1}/${3}" "${2}/${3}"
    else
        ln -s "${1}/${3}" "${2}/${3}"
    fi

    echo "* created: ${2}/${3}"
}

# no args
inhibitor() {
    ####################################
    echo "do not use yet; needs testing"

    exit 99
    ####################################
}

# no args
safety_check() {
    # Should not be root
    if [ `id -u` -eq 0 ]; then
        echo "do NOT run this as root (i.e., via sudo)"

        exit 1
    fi

    # Prevent unnecessary reruns
    if [ -e "${SYSTEM_HOME}/.hhh_configs_installed" ]; then
        echo "already installed."

        exit 2
    fi
}

# no args
setup_etc() {
    setup_etc_run_commands
    # TODO: process things under etc/ before going over home/ stuff
    #       for this I need a way to ask (future-)me whether I'd like to install
    #       these power settings
    #setup_etc_backup_files
    #setup_etc_install_files
}

# no args
setup_etc_run_commands() {
    echo "Configuring system-wide keyboard stuff; might ask root password."
    sudo localectl set-keymap us-colemak
    sudo localectl set-x11-keymap us pc104 colemak
}

# no args
setup_home_backup_files() {
    echo "Backup some of the existing stuff:"

    # .bashrc
    backup_and_report "${SYSTEM_HOME}/.bashrc" .bak true

    # .config/konsolerc => on hold, seems like konsole ignores this somehow???

    # .gnupg
    backup_and_report "${SYSTEM_HOME}/.gnupg"

    # .local/share/konsole/Hyun's.profile
    backup_and_report "${SYSTEM_HOME}/.local/share/konsole/Hyun's.profile"

    # .p10k.zsh
    backup_and_report "${SYSTEM_HOME}/.p10k.zsh"

    # .ssh/
    backup_and_report "${SYSTEM_HOME}/.ssh"

    # .zshrc
    backup_and_report "${SYSTEM_HOME}/.zshrc"
}

# no args
setup_home_install_files() {
    echo "Install new stuff:"

    # .bashrc
    cat "${PACKAGE_HOME}/.bashrc.addendum" >> "${SYSTEM_HOME}/.bashrc"
    echo "* updated: ${SYSTEM_HOME}/.bashrc"

    # .config/konsolerc => on hold, seems like konsole ignores this somehow???

    # .gnupg
    ## Recommended permissions
    install_and_report "${PACKAGE_HOME}" "${SYSTEM_HOME}" .gnupg true
    chmod 700 "${SYSTEM_HOME}/.gnupg"
    chmod 600 "${SYSTEM_HOME}/.gnupg/*.conf"
    ## Keyring is probably empty, so let's initialize it with my key
    curl --doh-url https://dns.quad9.net/dns-query --fail --location --silent \
        https://gitlab.com/hyunh.gpg \
    | gpg --import &> /dev/null

    # .local/share/konsole/Hyun's.profile
    install_and_report "${PACKAGE_HOME}" "${SYSTEM_HOME}" \
        ".local/share/konsole/Hyun's.profile"

    # .p10k.zsh
    install_and_report "${PACKAGE_HOME}" "${SYSTEM_HOME}" .p10k.zsh

    # .ssh/
    ## Recommended permissions
    chmod 700 "${PACKAGE_HOME}/.ssh"
    chmod 600 "${PACKAGE_HOME}/.ssh/config"
    ### Note: Even though this is a public key, ssh REQUIRES it to be treated as
    ###       sensitive info since it is used in ssh publickey authentication.
    chmod 600 "${PACKAGE_HOME}/.ssh/house.hwang.keys.pgp-ssh@hyun+public.txt"
    install_and_report "${PACKAGE_HOME}" "${SYSTEM_HOME}" .ssh

    # .zshrc
    install_and_report "${PACKAGE_HOME}" "${SYSTEM_HOME}" .zshrc
}

# no args
setup_home_run_commands() {
    # TODO: Integrate oh-my-zsh installation with --unattended --keep-zshrc
    # TODO: Install plugins:
    #       https://github.com/zsh-users/zsh-autosuggestions
    #       https://github.com/zsh-users/zsh-completions
    #       https://github.com/zsh-users/zsh-history-substring-search
    #       https://github.com/zsh-users/zsh-syntax-highlighting
    # TODO: Integrate powerlevel10k theme installation
}

# no args
mark_done() {
    # Mark installation done
    touch "${SYSTEM_HOME}/.hhh_configs_installed"
}
