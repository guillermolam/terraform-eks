#!/usr/bin/env python3
"""
validate-completeness.py

Checks that every Markdown file in docs/ has frontmatter and a title.
(You can expand this to suit your needs.)
"""
import glob
import os
import sys


def main():
    errors = 0
    for md in glob.glob("docs/**/*.md", recursive=True):
        with open(md) as f:
            text = f.read()
        if not text.startswith("---"):
            print(f"ERROR: {md} is missing YAML frontmatter")
            errors += 1
        if "# " not in text.splitlines()[0]:
            print(f"ERROR: {md} is missing a top-level title")
            errors += 1
    return errors


if __name__ == "__main__":
    sys.exit(main())
