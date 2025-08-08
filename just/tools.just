GOOS := `go env GOOS`
GOARCH := `go env GOARCH`

REPO_ROOT := justfile_directory()
LOCAL_DIR := REPO_ROOT + "/.local"
BIN_DIR := LOCAL_DIR + "/bin"

NKP_CLI_VERSION := "0.0.0-dev.0"  # TODO: Update to latest stable
NKP_CLI := BIN_DIR + "/nkp_v" + NKP_CLI_VERSION

# Download nkp CLI if it's not already present
[script]
nkp-cli:
  if [ ! -f "{{NKP_CLI}}" ]; then
    mkdir -p "{{BIN_DIR}}"
    echo "Downloading nkp CLI to {{NKP_CLI}}"

    asset="nkp_v{{NKP_CLI_VERSION}}_{{GOOS}}_amd64"
    url="https://downloads.d2iq.com/dkp/v{{NKP_CLI_VERSION}}/${asset}.tar.gz"

    curl -L --progress-bar "$url" | tar -xz -C .
    mv nkp "{{NKP_CLI}}"
  fi
