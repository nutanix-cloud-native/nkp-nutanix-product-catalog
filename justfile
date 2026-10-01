set unstable

import 'just/tools.just'
import 'just/validate.just'
import 'just/release.just'
import 'just/charts.just'

# Runs pre-commit hooks and gitlint against commits not in release-2.x.
pre-commit:
    env VIRTUALENV_PIP=24.0 pre-commit install-hooks
    pre-commit run -a --show-diff-on-failure
    git fetch --no-tags origin release-2.x
    git update-ref refs/gitlint/base FETCH_HEAD
    pre-commit run --hook-stage manual gitlint-ci
