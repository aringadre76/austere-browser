#!/usr/bin/env python3
import os
import sys
from pathlib import Path

def main():
    script_dir = Path(__file__).parent
    project_root = script_dir.parent.parent
    flags_file = project_root / "flags.gn"

    if flags_file.exists():
        with open(flags_file, 'r') as f:
            print(f.read())
    else:
        print("is_official_build=true", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
