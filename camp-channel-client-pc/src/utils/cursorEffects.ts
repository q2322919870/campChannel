/**
 * Theme-based Cursor Effects System
 * Each theme has unique cursor style, click effect, and movement trail
 */

export interface CursorEffect {
  cursor: string
  pointerCursor: string  // For clickable elements (buttons, links)
  textCursor: string     // For input fields
  clickEffect: 'ripple' | 'sparkle' | 'burst' | 'wave' | 'pulse' | 'glow' | 'particle' | 'none'
  trailEffect: 'dots' | 'line' | 'particles' | 'glow' | 'spiral' | 'none'
  trailColor?: string
  trailSize?: number
  clickColor?: string
}

export const cursorEffects: Record<number, CursorEffect> = {
  // 0: 雾蓝樱粉 - Elegant ripple with soft dots
  0: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'8\' fill=\'none\' stroke=\'%237C9FCB\' stroke-width=\'2\'/%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'3\' fill=\'%23F2B5D4\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2l3 6h6l-5 4 2 7-6-4-6 4 2-7-5-4h6z\' fill=\'%23F2B5D4\' stroke=\'%237C9FCB\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'10\' y=\'4\' width=\'4\' height=\'16\' fill=\'%237C9FCB\' rx=\'2\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'ripple',
    trailEffect: 'dots',
    trailColor: '#A8C4E8',
    trailSize: 4,
  },
  
  // 1: 湖蓝淡粉 - Water splash with wave trail
  1: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z\' fill=\'%234A9BD9\' opacity=\'0.6\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2l2 5h5l-4 3 1.5 5-4.5-3-4.5 3 1.5-5-4-3h5z\' fill=\'%23F5C6D0\' stroke=\'%234A9BD9\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M9 4h6v16h-2V12H9v8H7V4z\' fill=\'%234A9BD9\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'wave',
    trailEffect: 'line',
    trailColor: '#7BB8E8',
    trailSize: 3,
  },
  
  // 2: 鼠尾草淡黄 - Nature sparkle with particle trail
  2: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpolygon points=\'12,2 15,9 22,9 17,14 19,21 12,17 5,21 7,14 2,9 9,9\' fill=\'%239CAF88\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 C8 6, 6 10, 6 14 C6 18, 9 20, 12 22 C15 20, 18 18, 18 14 C18 10, 16 6, 12 2z\' fill=\'%23F5E6B8\' stroke=\'%239CAF88\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'11\' y=\'3\' width=\'2\' height=\'18\' fill=\'%239CAF88\' rx=\'1\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'sparkle',
    trailEffect: 'particles',
    trailColor: '#BCCDAA',
    trailSize: 5,
  },
  
  // 3: 薄荷孔雀绿 - Fresh burst with glow trail
  3: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'10\' fill=\'none\' stroke=\'%237EC8AE\' stroke-width=\'2\' stroke-dasharray=\'4 2\'/%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'4\' fill=\'%232E8B57\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L14 8 L20 8 L15 12 L17 18 L12 14 L7 18 L9 12 L4 8 L10 8 Z\' fill=\'%237EC8AE\' stroke=\'%232E8B57\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'2\' fill=\'%237EC8AE\'/%3E%3Cline x1=\'12\' y1=\'4\' x2=\'12\' y2=\'20\' stroke=\'%232E8B57\' stroke-width=\'2\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'burst',
    trailEffect: 'glow',
    trailColor: '#A3DCC8',
    trailSize: 6,
  },
  
  // 4: 玫红雪白 - Bold pulse with spiral trail
  4: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z\' fill=\'%23E84855\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 C6 6, 4 10, 4 14 C4 18, 8 22, 12 22 C16 22, 20 18, 20 14 C20 10, 18 6, 12 2z M12 6 C14 10, 16 12, 16 14 C16 16, 14 18, 12 18 C10 18, 8 16, 8 14 C8 12, 10 10, 12 6z\' fill=\'%23E84855\' stroke=\'%23F8F9FA\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M10 4h4v16h-2v-6h-2v6H8V4z\' fill=\'%23E84855\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'pulse',
    trailEffect: 'spiral',
    trailColor: '#F06A75',
    trailSize: 5,
  },
  
  // 5: 浅蓝薄荷 - Soft glow with dots
  5: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'6\' y=\'6\' width=\'12\' height=\'12\' rx=\'3\' fill=\'%23A0D2DB\' opacity=\'0.7\'/%3E%3Crect x=\'9\' y=\'9\' width=\'6\' height=\'6\' rx=\'1\' fill=\'%23B8E6D0\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L15 9 L22 9 L16 14 L18 21 L12 17 L6 21 L8 14 L2 9 L9 9 Z\' fill=\'%23B8E6D0\' stroke=\'%23A0D2DB\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'10\' y=\'4\' width=\'4\' height=\'16\' fill=\'%23A0D2DB\' rx=\'2\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'glow',
    trailEffect: 'dots',
    trailColor: '#C0E4EA',
    trailSize: 4,
  },
  
  // 6: 夜紫橙金 - Magic sparkle with particles
  6: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z\' fill=\'%236B4E9B\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L14 8 L20 8 L15 12 L17 18 L12 14 L7 18 L9 12 L4 8 L10 8 Z\' fill=\'%23F4A460\' stroke=\'%236B4E9B\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'11\' y=\'3\' width=\'2\' height=\'18\' fill=\'%236B4E9B\' rx=\'1\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'sparkle',
    trailEffect: 'particles',
    trailColor: '#8E6DB8',
    trailSize: 6,
  },
  
  // 7: 深蓝柔粉 - Deep ripple with line
  7: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'9\' fill=\'none\' stroke=\'%232C3E6B\' stroke-width=\'2.5\'/%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'5\' fill=\'%23E8B4C8\' opacity=\'0.8\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 C8 6, 6 10, 6 14 C6 18, 9 20, 12 22 C15 20, 18 18, 18 14 C18 10, 16 6, 12 2z\' fill=\'%23E8B4C8\' stroke=\'%232C3E6B\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M10 4h4v16h-2v-6h-2v6H8V4z\' fill=\'%232C3E6B\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'ripple',
    trailEffect: 'line',
    trailColor: '#4A5F8F',
    trailSize: 3,
  },
  
  // 8: 青绿奶杏 - Organic burst with glow
  8: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z\' fill=\'%233B7A6B\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L15 9 L22 9 L16 14 L18 21 L12 17 L6 21 L8 14 L2 9 L9 9 Z\' fill=\'%23F0E2C5\' stroke=\'%233B7A6B\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'10\' y=\'4\' width=\'4\' height=\'16\' fill=\'%233B7A6B\' rx=\'2\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'burst',
    trailEffect: 'glow',
    trailColor: '#5A9E8E',
    trailSize: 5,
  },
  
  // 9: 薄荷橙金 - Energy wave with spiral
  9: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpolygon points=\'12,3 19,12 12,21 5,12\' fill=\'%236BCB9E\'/%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'3\' fill=\'%23F4A460\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L14 8 L20 8 L15 12 L17 18 L12 14 L7 18 L9 12 L4 8 L10 8 Z\' fill=\'%23F4A460\' stroke=\'%236BCB9E\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'2\' fill=\'%236BCB9E\'/%3E%3Cline x1=\'12\' y1=\'4\' x2=\'12\' y2=\'20\' stroke=\'%23F4A460\' stroke-width=\'2\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'wave',
    trailEffect: 'spiral',
    trailColor: '#92DCB8',
    trailSize: 5,
  },
  
  // 10: 荧光水绿 - Neon particle with glow trail
  10: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'10\' fill=\'none\' stroke=\'%2339FF14\' stroke-width=\'2\' filter=\'drop-shadow(0 0 5px %2339FF14)\'/%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'5\' fill=\'%2300CED1\' filter=\'drop-shadow(0 0 3px %2300CED1)\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L15 9 L22 9 L16 14 L18 21 L12 17 L6 21 L8 14 L2 9 L9 9 Z\' fill=\'%2339FF14\' stroke=\'%2300CED1\' stroke-width=\'1\' filter=\'drop-shadow(0 0 3px %2339FF14)\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'11\' y=\'3\' width=\'2\' height=\'18\' fill=\'%2339FF14\' rx=\'1\' filter=\'drop-shadow(0 0 3px %2339FF14)\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'particle',
    trailEffect: 'glow',
    trailColor: '#7AFF5C',
    trailSize: 7,
  },
  
  // 11: 珊瑚玫瑰雾 - Romantic pulse with dots
  11: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z\' fill=\'%23FF7F7F\' opacity=\'0.8\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 C6 6, 4 10, 4 14 C4 18, 8 22, 12 22 C16 22, 20 18, 20 14 C20 10, 18 6, 12 2z M12 6 C14 10, 16 12, 16 14 C16 16, 14 18, 12 18 C10 18, 8 16, 8 14 C8 12, 10 10, 12 6z\' fill=\'%23FF7F7F\' stroke=\'%23E8C6D0\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M10 4h4v16h-2v-6h-2v6H8V4z\' fill=\'%23FF7F7F\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'pulse',
    trailEffect: 'dots',
    trailColor: '#FFAAAA',
    trailSize: 4,
  },
  
  // 12: 天蓝奶黄 - Sky sparkle with particles
  12: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2l2.4 7.2h7.6l-6 4.8 2.4 7.2-6-4.8-6 4.8 2.4-7.2-6-4.8h7.6z\' fill=\'%2387CEEB\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L14 8 L20 8 L15 12 L17 18 L12 14 L7 18 L9 12 L4 8 L10 8 Z\' fill=\'%23FFF5C2\' stroke=\'%2387CEEB\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'11\' y=\'3\' width=\'2\' height=\'18\' fill=\'%2387CEEB\' rx=\'1\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'sparkle',
    trailEffect: 'particles',
    trailColor: '#ADE0F2',
    trailSize: 5,
  },
  
  // 13: 雾青浅绿 - Gentle wave with line
  13: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'8\' fill=\'none\' stroke=\'%238FBC8F\' stroke-width=\'2\'/%3E%3Cpath d=\'M8 12 Q12 8 16 12 Q12 16 8 12\' fill=\'%23C8F0C8\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L15 9 L22 9 L16 14 L18 21 L12 17 L6 21 L8 14 L2 9 L9 9 Z\' fill=\'%23C8F0C8\' stroke=\'%238FBC8F\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'10\' y=\'4\' width=\'4\' height=\'16\' fill=\'%238FBC8F\' rx=\'2\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'wave',
    trailEffect: 'line',
    trailColor: '#B0D8B0',
    trailSize: 3,
  },
  
  // 14: 深绿薄荷 - Forest burst with glow
  14: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2L2 22h20L12 2zm0 4l6 14H6l6-14z\' fill=\'%232E7D32\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L14 8 L20 8 L15 12 L17 18 L12 14 L7 18 L9 12 L4 8 L10 8 Z\' fill=\'%234CAF50\' stroke=\'%232E7D32\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M10 4h4v16h-2v-6h-2v6H8V4z\' fill=\'%232E7D32\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'burst',
    trailEffect: 'glow',
    trailColor: '#4CAF50',
    trailSize: 6,
  },
  
  // 15: 电光蓝紫 - Electric particle with spiral
  15: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M7 2v11h3v9l7-12h-4l4-8z\' fill=\'%234B6CC2\' filter=\'drop-shadow(0 0 3px %234B6CC2)\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L14 8 L20 8 L15 12 L17 18 L12 14 L7 18 L9 12 L4 8 L10 8 Z\' fill=\'%23738ED6\' stroke=\'%234B6CC2\' stroke-width=\'1\' filter=\'drop-shadow(0 0 2px %234B6CC2)\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'11\' y=\'3\' width=\'2\' height=\'18\' fill=\'%234B6CC2\' rx=\'1\' filter=\'drop-shadow(0 0 2px %234B6CC2)\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'particle',
    trailEffect: 'spiral',
    trailColor: '#738ED6',
    trailSize: 6,
  },
  
  // 16: 绿松冰蓝 - Ice ripple with dots
  16: {
    cursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'9\' fill=\'none\' stroke=\'%2340E0D0\' stroke-width=\'2\'/%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'5\' fill=\'%23AEE2FF\' opacity=\'0.7\'/%3E%3Ccircle cx=\'12\' cy=\'12\' r=\'2\' fill=\'%2340E0D0\'/%3E%3C/svg%3E") 12 12, auto',
    pointerCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M12 2 L15 9 L22 9 L16 14 L18 21 L12 17 L6 21 L8 14 L2 9 L9 9 Z\' fill=\'%23AEE2FF\' stroke=\'%2340E0D0\' stroke-width=\'1\'/%3E%3C/svg%3E") 12 2, pointer',
    textCursor: 'url("data:image/svg+xml,%3Csvg width=\'24\' height=\'24\' viewBox=\'0 0 24 24\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Crect x=\'10\' y=\'4\' width=\'4\' height=\'16\' fill=\'%2340E0D0\' rx=\'2\'/%3E%3C/svg%3E") 12 12, text',
    clickEffect: 'ripple',
    trailEffect: 'dots',
    trailColor: '#72ECE0',
    trailSize: 4,
  },
}

export function getCursorEffect(themeIndex: number): CursorEffect {
  return cursorEffects[themeIndex] || cursorEffects[0]
}
