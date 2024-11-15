#!/bin/sh -e

# Prevent execution if this script was only partially downloaded
{
rc='\033[0m'
red='\033[0;31m'

# Check if curl is installed
if ! command -v curl >/dev/null 2>&1; then
    printf "${red}ERROR: curl is not installed. Please install curl to proceed.${rc}\n"
    exit 1
fi

download_url="https://console.icn.global/downloads"
version="v-0-1-1"
server_url="dac.api.icn.global:443"
config_url="https://api.icn.global/services/dac"

while getopts ":p:u:v:s:c:" option; do
   case $option in
      p)
        private_key=$OPTARG;;
      u)
        download_url=$OPTARG;;
      v)
        version=$OPTARG;;
      s)
        server_url=$OPTARG;;
      c)
        config_url=$OPTARG;;
     \?)
        echo "Error: Invalid option"
        exit 1;;
   esac
done

if [ -z "$private_key" ]; then
    printf "${red}ERROR: A private key must be provided as a parameter.${rc}\n"
    exit 1
fi

check() {
    exit_code=$1
    message=$2

    if [ "$exit_code" -ne 0 ]; then
        printf "${red}ERROR: %s${rc}\n" "$message"
        exit 1
    fi

    unset exit_code
    unset message
}

find_arch_and_os() {
    case "$(uname -m)" in
        x86_64*|amd64*) arch="amd64" ;;
        arm64*|aarch64*) arch="arm64" ;;
        *) check 1 "Unsupported architecture" ;;
    esac
    case "$(uname -s)" in
        Linux*) os="linux" ;;
        Darwin*) os="darwin" ;;
        *) check 1 "Unsupported OS" ;;
    esac
}

get_url() {
    echo "${download_url}/sla-oracle-node-${os}-${arch}-${version}"
}

find_arch_and_os
temp_file=$(mktemp)
check $? "Creating the temporary file"

curl -fsL "$(get_url)" -o "$temp_file"
check $? "Downloading sla-oracle-node"

chmod +x "$temp_file"
check $? "Making sla-oracle-node executable"
"$temp_file" -p "$private_key" --dac-client.server-endpoint "$server_url" --external-config.server-endpoint "$config_url"
check $? "Executing sla-oracle-node"

rm -f "$temp_file"
check $? "Deleting the temporary file"
} # End of wrapping
