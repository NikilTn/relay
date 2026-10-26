# Contributing

Keep changes small and preserve existing message IDs, account scopes, queued
requests and receipts. Human approval, cloud acceptance, relay storage and final
destination receipt are separate states. See [SECURITY.md](SECURITY.md).

## Local checks

```sh
swift test
python3.13 -m venv cloud/.venv
cloud/.venv/bin/python -m pip install -r cloud/requirements.lock
cloud/.venv/bin/python -m pytest cloud/tests -q
python3 scripts/tcp_experiment.py
```

The TCP experiment starts temporary same-host processes and stops them when done.
It does not establish physical wireless success. Run native iOS Simulator and
macOS builds after app changes; run the physical acceptance plan separately after
transport changes. Never describe fixture/Simulator output as physical evidence.

## Formatting

Swift uses Xcode's bundled `swift format`. Python uses Ruff 0.17.2, installed as a
development tool outside the app's runtime requirements.

```sh
swift format format --in-place --recursive App Sources Tests Package.swift scripts/generate_app_icon.swift
python3 -m pip install ruff==0.17.2
ruff format cloud scripts
ruff check cloud scripts
```

CI runs core/backend tests, Python correctness checks and formatting checks.
Regenerate the checked-in Xcode project with `python3 scripts/generate_project.py`
after changing its source list/settings. With no deployment environment variables,
this must produce the portable public defaults.

## Review checklist

- Explain the observable behavior and test evidence in the PR.
- Add regression tests for state, authorization, retry or schema changes.
- Do not add real user data, keys, sessions, audio, databases or signing material.
- Re-export OpenAPI after backend contract changes and review the diff.
- Preserve compatibility with already queued immutable requests.
- Keep `README.md`, `TEST_RESULTS.md` and relevant feature docs accurate.
- Run `gitleaks dir --redact .` and `gitleaks git --redact --log-opts="--all"` before publication.

Publication on October 26 sanitized historical paths, emails, hardware identifiers
and old evidence screenshots. Earlier commit hashes changed. If you have an old
clone, make a fresh clone and cherry-pick only reviewed work; do not merge old
unsanitized history back into the public repository.
