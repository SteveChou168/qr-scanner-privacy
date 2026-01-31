# Android App Icon (Adaptive Icon)

The app uses a custom icon with a gold star outline. To avoid the Android launcher shrinking the icon due to adaptive icon safe-zone cropping, we generate foreground PNGs with the icon scaled to **80%** of the 108dp adaptive icon canvas.

## How It Works

Adaptive icons use a 108dp canvas where only the inner 72dp (66.7%) is the visible safe zone. By placing the icon at 80% of the canvas, after cropping it fills the visible area without white borders.

## Regenerating Icons

Source icons are in `assets/LOGO/android_star_icons_noblur_diag_outline/res/`.

Use this Python script (requires Pillow) to regenerate foreground PNGs:

```python
from PIL import Image
import os

RATIO = 0.80  # Adjust if white border appears (increase) or icon gets clipped (decrease)

densities = {
    'mipmap-mdpi': 108,
    'mipmap-hdpi': 162,
    'mipmap-xhdpi': 216,
    'mipmap-xxhdpi': 324,
    'mipmap-xxxhdpi': 432,
}

src_base = 'assets/LOGO/android_star_icons_noblur_diag_outline/res'
dst_base = 'android/app/src/main/res'

for density, canvas_size in densities.items():
    icon = Image.open(f'{src_base}/{density}/ic_launcher.png').convert('RGBA')
    target = int(canvas_size * RATIO)
    icon_resized = icon.resize((target, target), Image.LANCZOS)
    canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = (canvas_size - target) // 2
    canvas.paste(icon_resized, (offset, offset), icon_resized)
    canvas.save(f'{dst_base}/{density}/ic_launcher_foreground.png')
```

## File Structure

| File | Purpose |
|------|---------|
| `mipmap-*/ic_launcher.png` | Legacy icon (pre-API 26) |
| `mipmap-*/ic_launcher_foreground.png` | Adaptive icon foreground (generated) |
| `mipmap-*/ic_launcher_round.png` | Round icon variant |
| `mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon config (white bg + foreground) |
| `mipmap-anydpi-v26/ic_launcher_round.xml` | Round adaptive icon config |

## Important Notes

- Do NOT add `ic_launcher_background.png` or `ic_launcher_monochrome.png` - they override the white background and cause sizing issues
- `AndroidManifest.xml` must have both `android:icon` and `android:roundIcon`
- Tested ratio: 80% fills the icon well. Range 72%-82% is safe; beyond 82% risks clipping on some launchers
