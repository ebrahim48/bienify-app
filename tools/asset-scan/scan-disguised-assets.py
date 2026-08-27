"""Find binary assets that are not what their extension claims.

The signature we are hunting: a file named like a font or an image whose bytes
do not carry that format's magic number, usually padded with whitespace so a
casual preview looks empty, with script hidden after the padding.
"""
import os
import re
import sys

ROOTS = [
    'D:/Jakuan/Projects/Telemedicine/bienify-app',
    'D:/Jakuan/Projects/Telemedicine/Backend-Beinify',
    'D:/Jakuan/Projects/Telemedicine/Dashboard',
]

SKIP_DIRS = {'.git', 'node_modules', 'build', '.dart_tool', '.gradle', 'dist',
             '.next', 'Pods', '.venv', '__pycache__'}

# extension -> list of acceptable leading byte signatures
MAGIC = {
    '.woff2': [b'wOF2'],
    '.woff': [b'wOFF'],
    '.ttf': [b'\x00\x01\x00\x00', b'true', b'ttcf'],
    '.otf': [b'OTTO', b'\x00\x01\x00\x00'],
    '.eot': [],  # loose format; checked only for script markers
    '.png': [b'\x89PNG\r\n\x1a\n'],
    '.jpg': [b'\xff\xd8\xff'],
    '.jpeg': [b'\xff\xd8\xff'],
    '.gif': [b'GIF87a', b'GIF89a'],
    '.webp': [b'RIFF'],
    '.ico': [b'\x00\x00\x01\x00', b'\x00\x00\x02\x00'],
    '.pdf': [b'%PDF'],
    '.mp4': [],  # box-based; script markers only
    '.zip': [b'PK\x03\x04', b'PK\x05\x06'],
    '.jar': [b'PK\x03\x04'],
    '.keystore': [],
    '.jks': [],
}

# Things that should never appear inside a font or an image.
SCRIPT_MARKERS = [
    (rb'_0x[0-9a-f]{4,}', 'hex-mangled identifiers (obfuscator output)'),
    (rb'\bglobal\s*\.\s*[A-Za-z_]', 'Node.js `global` access'),
    (rb'\beval\s*\(', 'eval('),
    (rb'new\s+Function\s*\(', 'new Function('),
    (rb'\brequire\s*\(\s*[\'"]', 'require('),
    (rb'child_process', 'child_process'),
    (rb'https?://[^\s\'"]{8,}', 'embedded URL'),
    (rb'process\s*\.\s*env', 'process.env'),
]

findings = []
checked = 0

for root in ROOTS:
    if not os.path.isdir(root):
        continue
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            ext = os.path.splitext(name)[1].lower()
            if ext not in MAGIC:
                continue
            path = os.path.join(dirpath, name)
            try:
                with open(path, 'rb') as fh:
                    head = fh.read(4096)
                    fh.seek(0)
                    body = fh.read(400_000)
            except OSError:
                continue
            checked += 1
            rel = os.path.relpath(path, os.path.dirname(root)).replace('\\', '/')

            reasons = []

            sigs = MAGIC[ext]
            if sigs and not any(head.startswith(s) for s in sigs):
                shown = ' '.join(f'{b:02x}' for b in head[:8])
                reasons.append(f'wrong magic bytes (starts {shown})')

            # whitespace padding is how the payload hides from a quick look
            lead = len(head) - len(head.lstrip(b' \t\r\n'))
            if lead >= 32:
                reasons.append(f'{lead} bytes of leading whitespace')

            for pattern, label in SCRIPT_MARKERS:
                if re.search(pattern, body):
                    reasons.append(f'contains {label}')

            if reasons:
                findings.append((rel, os.path.getsize(path), reasons))

print(f'Scanned {checked} binary assets across {len(ROOTS)} repositories.\n')
if not findings:
    print('No disguised files found in any working tree.')
else:
    print(f'{len(findings)} SUSPECT FILE(S):\n')
    for rel, size, reasons in findings:
        print(f'  {rel}  ({size:,} bytes)')
        for r in reasons:
            print(f'      - {r}')
        print()
sys.exit(0)
