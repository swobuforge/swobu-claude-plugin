#!/usr/bin/env python3
"""
Structural, SEO, and negative contract assertions for multilingual README lattice and marketplace metadata.
Governing RFC: docs/00-inbox/RFC 040 — Publish the Passive Claude Code Acquisition Lattice.md
"""

import os
import sys
import json
import re

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

FORBIDDEN_TERMS = [
    "zero client churn",
    "monotonic failover",
    "zero-downtime",
    "zero downtime",
    "unconditional failover",
    "error-wide failover",
    "perfect compatibility",
    "seamless compatibility",
    "bypass quota",
    "bypass rate limit",
    "bypass anthropic quota",
    "bypass billing",
    "available in 11 languages",
    "international discovery",
]

SECRET_PATTERNS = [
    r"sk-ant-[a-zA-Z0-9_\-]{20,}",
    r"sk-proj-[a-zA-Z0-9_\-]{20,}",
    r"AIzaSy[a-zA-Z0-9_\-]{30,}",
    r"ghp_[a-zA-Z0-9]{36}",
    r"gho_[a-zA-Z0-9]{36}",
    r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
]

def main():
    locales_path = os.path.join(ROOT_DIR, "locales.yaml")
    if not os.path.isfile(locales_path):
        print("ERROR: locales.yaml missing at root of plugin", file=sys.stderr)
        sys.exit(1)

    with open(locales_path, "r", encoding="utf-8") as f:
        content = f.read()

    readmes = re.findall(r"readme:\s*([^\s]+)", content)
    codes = re.findall(r"code:\s*([^\s]+)", content)

    if len(readmes) != 11 or len(codes) != 11:
        print(f"ERROR: expected 11 locales in locales.yaml, found {len(readmes)}", file=sys.stderr)
        sys.exit(1)

    canonical_commands = [
        "/plugin marketplace add swobuforge/swobu-claude-plugin",
        "/plugin install swobu@swobu",
        "/swobu:setup",
        "/swobu:connect",
    ]

    for readme_filename in readmes:
        readme_path = os.path.join(ROOT_DIR, readme_filename)
        if not os.path.isfile(readme_path):
            print(f"ERROR: missing localized README file: {readme_filename}", file=sys.stderr)
            sys.exit(1)

        try:
            with open(readme_path, "r", encoding="utf-8") as f:
                doc = f.read()
        except UnicodeDecodeError:
            print(f"ERROR: {readme_filename} is not valid UTF-8", file=sys.stderr)
            sys.exit(1)

        # 1. Reciprocal links to all other locales
        for target_readme in readmes:
            if target_readme not in doc:
                print(f"ERROR: {readme_filename} missing reciprocal link to {target_readme}", file=sys.stderr)
                sys.exit(1)

        # 2. Canonical install commands
        for cmd in canonical_commands:
            if cmd not in doc:
                print(f"ERROR: {readme_filename} missing canonical command: {cmd}", file=sys.stderr)
                sys.exit(1)

        # 3. Size sanity check
        if len(doc) < 500:
            print(f"ERROR: {readme_filename} is suspiciously short ({len(doc)} chars)", file=sys.stderr)
            sys.exit(1)

        # 4. RFC 040 Negative Contract Assertions
        lower_doc = doc.lower()
        for phrase in FORBIDDEN_TERMS:
            if phrase in lower_doc:
                print(f"ERROR: {readme_filename} contains forbidden claim: '{phrase}'", file=sys.stderr)
                sys.exit(1)

        # 5. Secret hygiene check
        for pattern in SECRET_PATTERNS:
            if re.search(pattern, doc):
                print(f"ERROR: {readme_filename} matched secret pattern '{pattern}'", file=sys.stderr)
                sys.exit(1)

    # Check marketplace metadata safety (Lane A)
    manifest_paths = [
        os.path.join(ROOT_DIR, ".claude-plugin", "plugin.json"),
        os.path.join(ROOT_DIR, ".claude-plugin", "marketplace.json"),
    ]
    manifest_forbidden_terms = [
        "deepseek",
        "qwen",
        "non-claude-models",
        "bypass",
        "run any model",
        "unsupported",
    ] + FORBIDDEN_TERMS

    for m_path in manifest_paths:
        with open(m_path, "r", encoding="utf-8") as f:
            raw = f.read().lower()
            for term in manifest_forbidden_terms:
                if term in raw:
                    print(f"ERROR: {m_path} contains forbidden marketplace claim: '{term}'", file=sys.stderr)
                    sys.exit(1)

    print("All 11 localized READMEs and marketplace metadata invariants verified against RFC 040.")

if __name__ == "__main__":
    main()
