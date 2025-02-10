#!/usr/bin/env bash
# Venafi CLI installer for Linux and macOS

set -euo pipefail
# Debug
# set -x

# Location of install log
: "${INSTALL_LOG:=/tmp/venafi-cli-install-$(date '+%Y%m%d-%H%M%S').log}"

: "${URL:= https://dl.venafi.cloud/}"

# Force Venafi CLI installation in this directory instead of system directory
: "${INSTALL_DIR:=}"

# Venafi CLI version to install
: "${VERSION:=}"


# global variables
binary_name="venctl"
binary=${binary_name}
cmd_shasum=""
cmd_sudo=""
dir_bin="/usr/bin"
footer_notes=""
has_sudo=""
kernel=""
machine=""
version=""
vaaskey_fingerprint="BA2F4B4442D945F0A2810A686B99EC1CEEE83892"
skip_signature_verifications=false

# create a log file where every output will be pipe to
pipe=/tmp/venafi-cli-install-$$.tmp
mkfifo $pipe
tee < $pipe $INSTALL_LOG &
exec 1>&-
exec 1>$pipe 2>&1
trap 'rm -f $pipe' EXIT

function output {
    style_start=""
    style_end=""
    if [ "${2:-}" != "" ]; then
    case $2 in
        "success")
            style_start="\033[0;32m"
            style_end="\033[0m"
            ;;
        "error")
            style_start="\033[31;31m"
            style_end="\033[0m"
            ;;
        "info")
            style_start=""
            style_end=""
            ;;
        "warning")
            style_start="\033[33m"
            style_end="\033[39m"
            ;;
        "heading")
            style_start="\033[1;36m"
            style_end="\033[22;39m"
            ;;
        "logo")
            style_start="\033[1;33m"
            style_end="\033[22;39m"
            ;;
        "comment")
            style_start="\033[2m"
            style_end="\033[22;39m"
            ;;
    esac
    fi

    builtin echo -e "${style_start}${1}${style_end}"
}

function exit_with_error() {
    output "  Installation failed!" "error"

    output "\nGet help with Venafi CLI:" "heading"
    output "  Inspect the logs: ${INSTALL_LOG}"
    output "  Read the docs: https://docs.venafi.cloud/vaas/venctl/c-venctl-overview/"
    output "  Get help: https://support.venafi.com/"

    exit 1
}

function exit_without_error() {
    output "\nGet help with Venafi CLI:" "heading"
    output "  Read the docs: https://docs.venafi.cloud/vaas/venctl/c-venctl-overview/"

    exit 0
}

function intro() {
    output " __      __               __ _     _____ _      _____ " "logo"
    output " \ \    / /              / _(_)   / ____| |    |_   _|" "logo"
    output "  \ \  / /__ _ __   __ _| |_ _   | |    | |      | |  " "logo"
    output "   \ \/ / _ \ '_ \ / _\` |  _| |  | |    | |      | | " "logo"
    output "    \  /  __/ | | | (_| | | | |  | |____| |____ _| |_ " "logo"
    output "     \/ \___|_| |_|\__,_|_| |_|   \_____|______|_____|" "logo"

    output "\nPrerequisite checks" "heading"
}

function outro() {
    output "  Venafi CLI has been installed successfully!" "success"

    output "\nUseful links:" "heading"
    output "  Venafi CLI introduction: https://docs.venafi.cloud/vaas/venctl/c-venctl-overview/"

    output "\nWhat's next?" "heading"
    output "  To use the Venafi CLI, run:" "output"
    if [ ! -z "$footer_notes" ]; then
        output "    ${binary} --help" "warning"

        output "\nWarning during installation:" "heading"
        output "$footer_notes" "warning"
    else
        output "    ${binary_name} --help" "warning"
    fi
}

function add_footer_note() {
    for var in "$@"; do
        if [ ! -z "$footer_notes" ]; then
            footer_notes="${footer_notes}\n${var}"
        else
            footer_notes="${footer_notes}${var}"
        fi
    done
}

function indent() {
    OLDIFS=$IFS
    IFS=$'\n'
    while read -r data; do
        line=$(echo "   | ${data}"|sed $'s/\r/\r   | /g'|sed $'s/\x1B\[[0-9;]\{1,\}[A-Za-z]//g')
        output "$line" "comment"
    done
    IFS=$OLDIFS
}

# Parse command-line arguments
parse_arguments() {
    while (( "$#" )); do
        case $1 in
            --skip-signature-verifications)
                skip_signature_verifications=true
                shift
                ;;
            *)
                output "Error: Unknown flag: ${1}" "error"
                exit_with_error
                ;;
        esac
    done
}

# Check that a command is installed
function check_command() {
    local cmd="${1}"
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        output "  [ ] ERROR: ${cmd} is required for installation" "error"
        exit_with_error
    fi
    output "  [*] ${cmd} is installed" "info"
}

# Check that gpg is installed, or prompt the user
function check_gpg() {
    if $skip_signature_verifications; then
        output "  [*] Signature verification is skipped as per user request" "info"
    else
        if command -v "gpg" >/dev/null 2>&1; then
            output "  [*] gpg is installed" "info"
        else
            if [ -t 0 ]; then  # Check if stdin is a terminal (interactive)
                output "  [ ] WARN: gpg command not found. This command is used to verify the authenticity of Venafi CLI." "warning"
                printf >&2 '%s ' ' Would you like to continue without signature verification? Yes/no: '
                read response
                response=$(echo $response | tr '[:upper:]' '[:lower:]')
                case "$response" in
                    yes|y)
                        skip_signature_verifications=true
                        output "  [*] continuing installation without signature verification" "info"
                        ;;
                    *)
                        output "  terminating installation" "info"
                        exit_without_error
                        ;;
                esac
            else
                output "  [ ] WARN: gpg command not found. Non-interactive mode detected; either install gpg first or re-run the script with 'bash -s -- --skip-signature-verifications'  flag to skip signature verifications." "warning"
                exit_without_error
            fi
        fi
    fi
}

# Check that Venafi CLI is not already installed
function check_venafi_cli() {
    if command -v ${binary_name} >/dev/null 2>&1; then
        output "  [*] Venafi CLI is already installed. Execute '${binary_name} --help' to get the more information." "info"
        update_venafi_cli
        exit_without_error
    else
        output "  [*] Venafi CLI is not installed" "info"
    fi
}

function check_version() {
    if [ -z "${VERSION}" ]; then
        version="latest"
        output "  [*] No version specified, using latest version" "info"
    else
        output "  [*] Version ${VERSION} specified" "info"
        version=${VERSION}
    fi
}

# Detect the kernel type
function check_kernel() {
    kernel=$(uname -s 2>$pipe || /usr/bin/uname -s)
    case ${kernel} in
        "Linux"|"linux")
            kernel="linux"
            ;;
        "Darwin"|"darwin")
            kernel="darwin"
            dir_bin="/usr/local/bin"
            ;;
        *)
            output "  [ ] Your OS (${kernel}) is currently not supported" "error"
            exit_with_error
            ;;
    esac

    output "  [*] Your OS (${kernel}) is supported" "info"
}

function check_architecture() {
    # Detect architecture
    machine=$(uname -m 2>$pipe || /usr/bin/uname -m)
    case ${machine} in
        aarch64*|armv8*|arm64*)
            machine="arm64"
            ;;
        i[36]86|x86)
            machine="386"
            ;;
        x86_64|amd64)
            machine="amd64"
            ;;
        *)
            output "  [ ] Your architecture (${machine}) is currently not supported" "error"
            exit_with_error
            ;;
    esac

    output "  [*] Your architecture (${machine}) is supported" "info"
}


function init_sudo() {
    if [ ! -z "${has_sudo}" ]; then
        return
    fi

    has_sudo=false
    # Are we running the installer as root?
    if [ "$(echo "$UID")" = "0" ]; then
        has_sudo=true
        cmd_sudo=''

        return
    fi

    if command -v sudo > /dev/null 2>&1; then
        has_sudo=true
        cmd_sudo='sudo -E'
    fi
}

function call_root() {
    init_sudo

    if ! ${has_sudo}; then
        output "  sudo is required to perform this operation" "error"
        exit_with_error
    fi

    if $cmd_sudo sh -c "$1" 2>&1 | indent; then
        return 0
    fi

    return 1
}

function call_try_user() {
    if ! call_user "$1"; then
        output "  command failed; retrying with sudo. Enter your sudo password if prompted." "warning"
        if ! call_root "$1"; then
            output "  ${2:-command failed}" "error"
            exit_with_error
        fi
    fi
}

function call_user() {
    sh -c "$1" 2>&1 | indent
}

function check_shasum() {
    if command -v sha256sum > /dev/null 2>&1; then
        cmd_shasum="sha256sum"
        output "  [*] sha256sum is installed" "info"
    elif command -v shasum > /dev/null 2>&1; then
        cmd_shasum="shasum -a 256"
        output "  [*] shasum is installed" "info"
    else
        output "  [ ] No sha256sum or shasum available to verify binary" "error"
        exit_with_error
    fi
}

function check_directories() {
    if [ ! -z "${INSTALL_DIR}" ]; then
        dir_bin="${INSTALL_DIR}"
    fi

    if ! echo $PATH | grep ${dir_bin} > /dev/null; then
        binary="${dir_bin}/${binary_name}"

        output "  [ ] ${dir_bin} is not in \$PATH.\n" "warning"
        add_footer_note "    The directory \"${dir_bin}\" is not in \$PATH"
        if echo $SHELL | grep '/bin/zsh' > /dev/null
        then
            add_footer_note \
                "    Run this command to add the directory to your PATH" \
                "    echo 'export PATH=\"${dir_bin}:\$PATH\"' >> \$HOME/.zshrc"
        elif echo $SHELL | grep '/bin/bash' > /dev/null
        then
            add_footer_note \
                "    Run this command to add the directory to your PATH" \
                "    echo 'export PATH=\"${dir_bin}:\$PATH\"' >> \$HOME/.bashrc"
        else
            add_footer_note \
                "    You can add it to your PATH by adding this line at the end of your shell configuration file" \
                "    export PATH=\"${dir_bin}:\$PATH\""
        fi
    else
        output "  [*] ${dir_bin} is in \$PATH" "info"
    fi

    output "\nTarget directory" "heading"
    output "  Binary will be installed in ${dir_bin}"
}

function update_venafi_cli {
    output "\nUpdating Venafi CLI" "heading"
    update_command="${binary_name} update --no-prompts"
    call_try_user "${update_command}" "Failed to update. Execute ${update_command} to update it manually."

    output "  Venafi CLI has been updated successfully!" "success"
}

function download {
    #TODO: Try wget if curl is not installed
    curl -fsSL $1
    return $?
}

# to be able to run the checksum check, $cmd_shasum must be called
# from the same directory where the content is stored
function verifyIntegrity() {
  current="$PWD"
  cd "$1"
  $cmd_shasum --ignore-missing -c "$1/$2" --status
  cd "$current"
}

function verifySignature() {
   gpg --no-default-keyring --keyring $1 --verify $2 $3 2>&1 | grep --quiet --word-regexp $vaaskey_fingerprint
}

function updateKeyring() {
  gpg --no-default-keyring --keyring $1 --import $2 > /dev/null 2>&1
}

function install_venafi_cli() {
    tmp_dir=$(mktemp -d)
    tmp_name="${binary_name}-${kernel}-${machine}"
    keyring_name="venctl.gpg"

    pubkey_url="${URL}vaaskey.pub"
    archive_url="${URL}${binary_name}/${version}/${tmp_name}.zip"
    checksum_url="${URL}${binary_name}/${version}/${binary_name}-SHA256SUMS"
    signature_url="${archive_url}.sig"

    # Download the public key
    output "  Downloading ${pubkey_url}";
    if ! download "$pubkey_url" > "${tmp_dir}/vaaskey.pub"; then
        output "  the venafi public key download failed" "error"
        exit_with_error
    fi

    if ! ${skip_signature_verifications}; then
        # Add public key to the keyring
        if ! updateKeyring "${tmp_dir}/${keyring_name}" "${tmp_dir}/vaaskey.pub"; then
          output "  unable to update host gpg keyring with venafi key" "error"
          exit_with_error
        fi
    fi


    # Download the Venafi CLI archive
    output "\nDownloading the Venafi CLI" "heading"
    output "  Downloading ${archive_url}";
    if ! download "$archive_url" > "${tmp_dir}/${tmp_name}.zip"; then
        output "  the archive download failed ${archive_url}" "error"
        exit_with_error
    fi

    # verify the checksum
    output "  Downloading ${checksum_url}";
    if ! download "$checksum_url" > "${tmp_dir}/${binary_name}-SHA256SUMS"; then
      output "  the checksum download failed ${checksum_url}" "error"
      exit_with_error
    fi

    # Download the signature and verify
    output "  Downloading ${signature_url}";
    if ! download "$signature_url" > "${tmp_dir}/${tmp_name}.zip.sig"; then
      output "  the signature download failed ${signature_url}" "error"
      exit_with_error
    fi

    output "\nVerifying the integrity and authenticity of Venafi CLI" "heading"
    if ! verifyIntegrity "${tmp_dir}" "${binary_name}-SHA256SUMS"; then
      output "  could not verify the archive integrity" "error"
      exit_with_error
    fi
    output "  The integrity of the downloaded archive has been verified";

    if ! ${skip_signature_verifications}; then
        output " Verifying archive authenticity"
        if ! verifySignature "${tmp_dir}/${keyring_name}" "${tmp_dir}/${tmp_name}.zip.sig" "${tmp_dir}/${tmp_name}.zip"; then
          output "  could not verify the archive authenticity" "error"
          exit_with_error
        fi
        output "  archive was verified";
    fi

    output "  Uncompressing archive"
    if ! unzip -q "${tmp_dir}/${tmp_name}.zip" -d "${tmp_dir}"; then
      output "  unable to extract the downloaded archive." "error"
      exit_with_error
    fi

    if ! ${skip_signature_verifications}; then
      output " Verifying binary authenticity"
      if ! verifySignature "${tmp_dir}/${keyring_name}" "${tmp_dir}/${binary_name}.sig" "${tmp_dir}/${binary_name}"; then
         output "  could not verify the binary authenticity" "error"
         exit_with_error
      fi
      output "  binary was verified";
    fi

    output "\nInstalling the Venafi CLI" "heading"

    output "  Making the binary executable"
    chmod 0755 "${tmp_dir}/${binary_name}"

    if [ ! -d "$dir_bin" ]; then
        output "  Creating ${dir_bin} directory"
        call_try_user "mkdir -p ${dir_bin}" "Failed to create the ${dir_bin} directory"
    fi

    output "  Installing the binary under ${dir_bin}"
    binary="${dir_bin}/${binary_name}"
    call_try_user "mv '${tmp_dir}/${binary_name}' '${binary}'" "Failed to move the binary ${binary}"
}

intro
parse_arguments "$@"
check_venafi_cli
check_kernel
check_architecture
check_command "curl"
check_command "unzip"
check_command "tr"
check_version
check_shasum
check_gpg
check_directories
install_venafi_cli
outro
