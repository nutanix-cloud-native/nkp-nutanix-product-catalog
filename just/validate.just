# Validate each application artifact w.r.t the .bloodhound.yml config.
validate-manifests: nkp-cli
    "{{ NKP_CLI }}" validate catalog-repository -v=3 --repo-dir="{{ REPO_ROOT }}"
