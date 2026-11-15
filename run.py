#!/usr/bin/env python3
"""Start IED Doctor:  python run.py   (add --help for options)"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ied_doctor.app import main  # noqa: E402

if __name__ == "__main__":
    main()
