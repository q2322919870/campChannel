// Script to add pointerCursor and textCursor to all theme definitions
// Run this in Node.js to update cursorEffects.ts

const fs = require('fs');
const path = require('path');

const filePath = path.join(__dirname, '../src/utils/cursorEffects.ts');
let content = fs.readFileSync(filePath, 'utf8');

// Theme color mappings (primary, accent)
const themeColors = [
  ['#7C9FCB', '#F2B5D4'], // 0: 雾蓝樱粉
  ['#4A9BD9', '#F5C6D0'], // 1: 湖蓝淡粉
  ['#9CAF88', '#F5E6B8'], // 2: 鼠尾草淡黄
  ['#7EC8AE', '#2E8B57'], // 3: 薄荷孔雀绿
  ['#E84855', '#F8F9FA'], // 4: 玫红雪白
  ['#A0D2DB', '#B8E6D0'], // 5: 浅蓝薄荷
  ['#6B4E9B', '#F4A460'], // 6: 夜紫橙金
  ['#2C3E6B', '#E8B4C8'], // 7: 深蓝柔粉
  ['#3B7A6B', '#F0E2C5'], // 8: 青绿奶杏
  ['#6BCB9E', '#F4A460'], // 9: 薄荷橙金
  ['#39FF14', '#00CED1'], // 10: 荧光水绿
  ['#FF7F7F', '#E8C6D0'], // 11: 珊瑚玫瑰雾
  ['#87CEEB', '#FFF5C2'], // 12: 天蓝奶黄
  ['#8FBC8F', '#C8F0C8'], // 13: 雾青浅绿
  ['#2E7D32', '#A5D6A7'], // 14: 深绿薄荷
  ['#4B6CC2', '#9B59B6'], // 15: 电光蓝紫
  ['#40E0D0', '#AEE2FF'], // 16: 绿松冰蓝
];

// Add pointer and text cursors to each theme
themeColors.forEach(([primary, accent], index) => {
  const encodedPrimary = encodeURIComponent(primary);
  const encodedAccent = encodeURIComponent(accent);
  
  const pointerSVG = `url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M12 2l3 6h6l-5 4 2 7-6-4-6 4 2-7-5-4h6z' fill='${encodedAccent}' stroke='${encodedPrimary}' stroke-width='1'/%3E%3C/svg%3E") 12 2, pointer`;
  const textSVG = `url("data:image/svg+xml,%3Csvg width='24' height='24' viewBox='0 0 24 24' xmlns='http://www.w3.org/2000/svg'%3E%3Crect x='10' y='4' width='4' height='16' fill='${encodedPrimary}' rx='2'/%3E%3C/svg%3E") 12 12, text`;
  
  // Find the theme block and add the properties after cursor line
  const themeRegex = new RegExp(`(\\s+${index}: \\{[\\s\\S]*?cursor: '[^']+',)(\\s+clickEffect:)`, 'g');
  
  if (content.match(themeRegex)) {
    content = content.replace(themeRegex, `$1\n    pointerCursor: '${pointerSVG}',\n    textCursor: '${textSVG}',$2`);
  }
});

// Remove the helper function we added earlier
content = content.replace(/\s+\/\/ Helper to generate themed cursors[\s\S]*?\}\),/, '');

fs.writeFileSync(filePath, content, 'utf8');
console.log('✓ Added pointerCursor and textCursor to all themes');
