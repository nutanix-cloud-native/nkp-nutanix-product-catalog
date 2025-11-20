import 'just/tools.just'
import 'just/validate.just'
import 'just/release.just'

# Runs pre-commit hooks and gitlint
pre-commit:
    env VIRTUALENV_PIP=24.0 pre-commit install-hooks
    pre-commit run -a --show-diff-on-failure
    git fetch origin main
    pre-commit run --hook-stage manual gitlint-ci
