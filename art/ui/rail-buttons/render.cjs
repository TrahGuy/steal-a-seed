// Renders the Shop button's rim-cut base and the two 256-px copies the game uploads.
// Same renderer as the approved exports (D:\KAPE\output\ui-icons-v1\render.cjs): sharp,
// which re-renders shop.svg and index.svg pixel-identical to the approved PNGs.
// Run with the Codex runtime's Node (this machine has no other):
//   C:\Users\Maykel\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe render.cjs
const path = require('path');
const sharp = require('C:/Users/Maykel/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const here = (name) => path.join(__dirname, name);
(async () => {
  await sharp(here('shop-base.svg')).png().toFile(here('shop-base.png'));
  // 256: the buttons draw at 50 px, 150 on a 3x phone and 135 on a 4K TV.
  for (const name of ['shop-base', 'index']) {
    await sharp(here(name + '.png')).resize(256, 256, { kernel: 'lanczos3' }).png().toFile(here(name + '-256.png'));
  }
  console.log('shop-base.png, shop-base-256.png, index-256.png');
})().catch((e) => { console.error(e); process.exit(1); });
