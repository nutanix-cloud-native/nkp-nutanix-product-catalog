GOOS := `go env GOOS`
GOARCH := `go env GOARCH`

REPO_ROOT := justfile_directory()
LOCAL_DIR := REPO_ROOT+"/.local"

# TODO: update the version to latest stable once available
NKP_CLI_VERSION := "0.0.0-dev.0"
NKP_CLI := LOCAL_DIR+"/bin/nkp_v"+NKP_CLI_VERSION
NKP_CLI_ASSET := "nkp_v"+NKP_CLI_VERSION+"_"+GOOS+"_amd64"

# Command line tool to validate the catalog applications.
nkp-cli:
    [ -f "{{NKP_CLI}}" ] || ( \
        echo "Building {{NKP_CLI}}..." && \
        mkdir -p "{{LOCAL_DIR}}/bin" && \
        curl -LO "https://downloads.d2iq.com/dkp/v{{NKP_CLI_VERSION}}/{{NKP_CLI_ASSET}}.tar.gz" && tar -xzf "{{NKP_CLI_ASSET}}.tar.gz" -C . && \
        mv ./nkp "{{NKP_CLI}}" && \
        echo "Successfully built {{NKP_CLI}}." \
    )
