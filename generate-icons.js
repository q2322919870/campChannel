// Generate tab bar icons as simple colored 48x48 PNG files
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const OUT_DIR = path.join(__dirname, 'camp-channel-client-uniapp', 'src', 'static', 'tab');

// Tab icon configs: [name, r, g, b]
const tabs = [
  ['home', 124, 159, 203],    // #7C9FCB - primary blue
  ['channel', 162, 210, 255], // light blue
  ['chat', 242, 181, 212],    // #F2B5D4 - accent pink
  ['notify', 250, 210, 150],  // warm yellow
  ['profile', 160, 200, 180], // soft green
];

function crc32(buf) {
  let crc = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) {
    crc ^= buf[i];
    for (let j = 0; j < 8; j++) {
      crc = (crc & 1) ? ((crc >>> 1) ^ 0xEDB88320) : (crc >>> 1);
    }
  }
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function createChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const typeB = Buffer.from(type, 'ascii');
  const crcData = Buffer.concat([typeB, data]);
  const crc = crc32(crcData);
  const crcB = Buffer.alloc(4);
  crcB.writeUInt32BE(crc);
  return Buffer.concat([len, typeB, data, crcB]);
}

function makePNG(w, h, r, g, b) {
  const raw = Buffer.alloc(h * (1 + w * 4));
  const cx = w / 2, cy = h / 2, radius = Math.min(w, h) / 2 - 2;
  for (let y = 0; y < h; y++) {
    const rowOff = y * (1 + w * 4);
    raw[rowOff] = 0; // filter: none
    for (let x = 0; x < w; x++) {
      const dx = x - cx, dy = y - cy;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const po = rowOff + 1 + x * 4;
      if (dist <= radius) {
        // Inner circle with gradient
        const alpha = Math.min(255, Math.max(0, Math.round((1 - dist / radius) * 80 + 175)));
        raw[po] = r; raw[po+1] = g; raw[po+2] = b; raw[po+3] = alpha;
      } else if (dist <= radius + 3) {
        // Anti-alias edge
        const aa = Math.max(0, Math.round((1 - (dist - radius) / 3) * 255));
        raw[po] = r; raw[po+1] = g; raw[po+2] = b; raw[po+3] = aa;
      } else {
        raw[po] = 0; raw[po+1] = 0; raw[po+2] = 0; raw[po+3] = 0;
      }
    }
  }
  const compressed = zlib.deflateSync(raw);
  // Signature
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  // Selected variant: filled circle (no stroke)
  return Buffer.concat([sig, createChunk('IHDR', ihdr), createChunk('IDAT', compressed), createChunk('IEND', Buffer.alloc(0))]);
}

// Ensure output directory exists
if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

for (const [name, r, g, b] of tabs) {
  const png = makePNG(48, 48, r, g, b);
  fs.writeFileSync(path.join(OUT_DIR, `${name}.png`), png);
  console.log(`Created ${name}.png (${png.length} bytes)`);
}

// Also create selected (filled/lighter) versions
for (const [name, r, g, b] of tabs) {
  const png = makePNG(48, 48, Math.min(255, r + 40), Math.min(255, g + 40), Math.min(255, b + 40));
  fs.writeFileSync(path.join(OUT_DIR, `${name}-active.png`), png);
  console.log(`Created ${name}-active.png (${png.length} bytes)`);
}

console.log('Done!');
