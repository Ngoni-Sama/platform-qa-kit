#!/usr/bin/env python3
"""Build dist/platform-qa.zip for uploading in the Claude app (Customize > Skills).

The skill folder must sit at the root of the ZIP and match the skill name.
Run after editing the skill:  python build_zip.py
"""
import os
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
SKILL = os.path.join(ROOT, "plugins", "platform-qa", "skills", "platform-qa")
OUT = os.path.join(ROOT, "dist", "platform-qa.zip")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as zf:
    for folder, _dirs, files in os.walk(SKILL):
        for name in sorted(files):
            if name.endswith((".pyc",)) or name.startswith("."):
                continue
            path = os.path.join(folder, name)
            arc = os.path.join("platform-qa", os.path.relpath(path, SKILL)).replace(os.sep, "/")
            zf.write(path, arc)
with zipfile.ZipFile(OUT) as zf:
    names = zf.namelist()
print(f"Built {os.path.relpath(OUT, ROOT)} with {len(names)} files:")
for n in names:
    print("  " + n)
