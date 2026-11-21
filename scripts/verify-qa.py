from pathlib import Path
from struct import unpack

root = Path(__file__).resolve().parents[1] / 'qa'
names = 'menu-shown menu-hidden tip-1 tip-2 tip-3 settings-general settings-behaviour settings-behaviour-off settings-about icon-1x icon-2x icon-4x'.split()
for name in names:
    data = (root / (name + '.png')).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', name
    w, h = unpack('>II', data[16:24])
    assert w > 0 and h > 0, name
print(f'PASS  {len(names)} PNGs present')
