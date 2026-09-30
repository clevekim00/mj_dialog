// Run with Node.js and the `sharp` package available (for example via NODE_PATH).
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '../..');
const source = fs.readFileSync(path.join(root, 'assets/branding/app-icon.svg'), 'utf8');
async function png(file, size, mode = 'square') {
  let svg = source;
  if (mode === 'rounded') svg = svg.replace('rx="0"', 'rx="224"');
  if (mode === 'maskable') svg = svg.replace('<g id="symbol">', '<g id="symbol" transform="translate(128 128) scale(0.75)">');
  const dest = path.join(root, file);
  fs.mkdirSync(path.dirname(dest), {recursive: true});
  let image = sharp(Buffer.from(svg)).resize(size, size);
  if (mode !== 'rounded') image = image.flatten({background: '#18594E'}).removeAlpha();
  await image.png().toFile(dest);
}
(async () => {
  for (const platform of ['ios', 'macos']) {
    const dir = `${platform}/Runner/Assets.xcassets/AppIcon.appiconset`;
    const entries = JSON.parse(fs.readFileSync(path.join(root, dir, 'Contents.json'))).images;
    for (const entry of entries) {
      if (entry.filename) await png(`${dir}/${entry.filename}`, Math.round(parseFloat(entry.size) * parseFloat(entry.scale)), platform === 'macos' ? 'rounded' : 'square');
    }
  }
  for (const [density,size] of Object.entries({mdpi:48,hdpi:72,xhdpi:96,xxhdpi:144,xxxhdpi:192})) {
    await png(`android/app/src/main/res/mipmap-${density}/ic_launcher.png`, size, 'rounded');
  }
  for (const size of [192,512]) {
    await png(`web/icons/Icon-${size}.png`, size);
    await png(`web/icons/Icon-maskable-${size}.png`, size, 'maskable');
  }
  await png('web/favicon.png', 32, 'rounded');
  await png('assets/branding/app-icon.png', 512, 'rounded');
  await png('linux/runner/resources/app-icon.png', 256, 'rounded');
  console.log('Generated platform PNG icons from app-icon.svg');
})();
