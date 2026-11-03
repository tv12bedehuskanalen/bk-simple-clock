#!/usr/bin/env python3
"""Package the source PNG as native macOS and Windows icons (macOS build tools)."""
from pathlib import Path
import struct
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
source = root / 'assets/bk-big-clock-v2.png'
with tempfile.TemporaryDirectory() as tmp:
    folder = Path(tmp) / 'Clock.iconset'
    folder.mkdir()
    for base in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            size = base * scale
            suffix = '@2x' if scale == 2 else ''
            target = folder / f'icon_{base}x{base}{suffix}.png'
            subprocess.run(['sips', '-z', str(size), str(size), str(source), '--out', str(target)], check=True, stdout=subprocess.DEVNULL)
    chunks = []
    for name, code in [('icon_16x16.png', b'icp4'), ('icon_32x32.png', b'icp5'), ('icon_32x32@2x.png', b'icp6'), ('icon_128x128.png', b'ic07'), ('icon_256x256.png', b'ic08'), ('icon_512x512.png', b'ic09'), ('icon_512x512@2x.png', b'ic10')]:
        data = (folder / name).read_bytes()
        chunks.append(code + struct.pack('>I', len(data) + 8) + data)
    content = b''.join(chunks)
    (root / 'assets/Clock.icns').write_bytes(b'icns' + struct.pack('>I', len(content) + 8) + content)
    entries = []
    payloads = []
    offset = 6 + 16 * 6
    for size in (16, 32, 48, 64, 128, 256):
        target = Path(tmp) / f'{size}.png'
        subprocess.run(['sips', '-z', str(size), str(size), str(source), '--out', str(target)], check=True, stdout=subprocess.DEVNULL)
        data = target.read_bytes()
        entries.append(struct.pack('<BBBBHHII', size % 256, size % 256, 0, 0, 1, 32, len(data), offset))
        payloads.append(data)
        offset += len(data)
    (root / 'assets/Clock.ico').write_bytes(struct.pack('<HHH', 0, 1, len(entries)) + b''.join(entries + payloads))
