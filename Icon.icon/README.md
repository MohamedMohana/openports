# Icon Assets

This directory contains the Icon Studio format for the OpenPorts app icon.

## Icon Design

Professional SF Symbol-based design:
- **Base**: SF Symbol `network` (circle with arrows)
- **Overlay**: Port icon (small `x.circle.fill` badge)
- **Colors**: System blue (macOS accent) + subtle gradient
- **Sizes**: 16pt, 32pt, 128pt, 256pt, 512pt, 1024pt

## Generating Icon Images

You can generate the icon images using macOS's `sflib` command:

```bash
# Generate all required sizes
for size in 16 32 128 256 512 1024; do
  sflib print --symbol network --format png --size $size --color blue Icon.icon/Assets/openports-${size}.png
  if [ "$size" -le 32 ]; then
    sflib print --symbol network --format png --size $((size * 2)) --color blue Icon.icon/Assets/openports-${size}@2x.png
  fi
done
```

Alternatively, use Figma, Sketch, or Adobe Illustrator to create custom icon designs and export as PNG files.

## Converting to .icns

The build script (`Scripts/package_app.sh`) will automatically convert `.icon` to `.icns` using macOS's `iconutil` command.

```bash
iconutil --convert icns --output Icon.icns Icon.icon
```
