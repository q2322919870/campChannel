/**
 * Canvas-based Page Transition Effects
 * Each theme has unique HTML-in-Canvas transition animation
 */

export interface CanvasTransitionEffect {
  name: string
  duration: number // milliseconds
  effect: 'particles' | 'waves' | 'morph' | 'dissolve' | 'pixelate' | 'liquid' | 'shatter' | 'glitch' | 'ripple' | 'fireworks' | 'snow' | 'rain' | 'spiral' | 'vortex' | 'matrix' | 'aurora' | 'nebula' | 'crystal'
  config?: Record<string, any>
}

export const canvasTransitions: Record<number, CanvasTransitionEffect> = {
  // 0: 雾蓝樱粉 - Cherry blossom particles
  0: {
    name: 'Sakura Particles',
    duration: 400,
    effect: 'particles',
    config: {
      particleCount: 80,
      colors: ['#7C9FCB', '#F2B5D4', '#A8C4E8'],
      size: [3, 8],
      speed: [2, 5],
      shape: 'petal',
    },
  },

  // 1: 湖蓝淡粉 - Water waves
  1: {
    name: 'Water Waves',
    duration: 350,
    effect: 'waves',
    config: {
      waveCount: 5,
      amplitude: 50,
      frequency: 0.02,
      colors: ['#4A9BD9', '#7BB8E8', '#F5C6D0'],
      direction: 'horizontal',
    },
  },

  // 2: 鼠尾草淡黄 - Organic morph
  2: {
    name: 'Nature Morph',
    duration: 450,
    effect: 'morph',
    config: {
      segments: 12,
      colors: ['#9CAF88', '#F5E6B8', '#BCCDAA'],
      morphType: 'organic',
      smoothness: 0.8,
    },
  },

  // 3: 薄荷孔雀绿 - Liquid dissolve
  3: {
    name: 'Mint Dissolve',
    duration: 400,
    effect: 'dissolve',
    config: {
      resolution: 8,
      colors: ['#7EC8AE', '#2E8B57', '#A3DCC8'],
      dissolvePattern: 'liquid',
      spread: 1.5,
    },
  },

  // 4: 玫红雪白 - Pixel explosion
  4: {
    name: 'Rose Pixels',
    duration: 300,
    effect: 'pixelate',
    config: {
      pixelSize: 15,
      colors: ['#E84855', '#F8F9FA', '#F06A75'],
      explosionForce: 8,
      gravity: 0.3,
    },
  },

  // 5: 浅蓝薄荷 - Shatter glass
  5: {
    name: 'Mist Shatter',
    duration: 350,
    effect: 'shatter',
    config: {
      shardCount: 60,
      colors: ['#A0D2DB', '#B8E6D0', '#C0E4EA'],
      shatterPattern: 'radial',
      rotation: true,
    },
  },

  // 6: 夜紫橙金 - Digital glitch
  6: {
    name: 'Magic Glitch',
    duration: 300,
    effect: 'glitch',
    config: {
      glitchIntensity: 20,
      colors: ['#6B4E9B', '#F4A460', '#8E6DB8'],
      sliceCount: 15,
      offsetRange: 30,
    },
  },

  // 7: 深蓝柔粉 - Ripple expansion
  7: {
    name: 'Deep Ripple',
    duration: 400,
    effect: 'ripple',
    config: {
      rippleCount: 8,
      colors: ['#2C3E6B', '#E8B4C8', '#4A5F8F'],
      startRadius: 0,
      endRadius: 1.5,
      speed: 2,
    },
  },

  // 8: 青绿奶杏 - Firework burst
  8: {
    name: 'Teal Fireworks',
    duration: 450,
    effect: 'fireworks',
    config: {
      fireworkCount: 12,
      colors: ['#3B7A6B', '#F0E2C5', '#5A9E8E'],
      particleCount: 40,
      explosionRadius: 200,
    },
  },

  // 9: 薄荷橙金 - Spiral vortex
  9: {
    name: 'Energy Spiral',
    duration: 400,
    effect: 'spiral',
    config: {
      spiralArms: 6,
      colors: ['#6BCB9E', '#F4A460', '#92DCB8'],
      rotationSpeed: 0.15,
      expansionRate: 1.2,
    },
  },

  // 10: 荧光水绿 - Matrix rain
  10: {
    name: 'Neon Matrix',
    duration: 350,
    effect: 'matrix',
    config: {
      columnCount: 30,
      colors: ['#39FF14', '#00CED1', '#7AFF5C'],
      charSpeed: 8,
      fadeRate: 0.05,
    },
  },

  // 11: 珊瑚玫瑰雾 - Snow fall
  11: {
    name: 'Romantic Snow',
    duration: 450,
    effect: 'snow',
    config: {
      flakeCount: 100,
      colors: ['#FF7F7F', '#E8C6D0', '#FFAAAA'],
      size: [2, 6],
      fallSpeed: [1, 3],
      sway: true,
    },
  },

  // 12: 天蓝奶黄 - Rain drops
  12: {
    name: 'Sky Rain',
    duration: 400,
    effect: 'rain',
    config: {
      dropCount: 80,
      colors: ['#87CEEB', '#FFF5C2', '#ADE0F2'],
      length: [15, 30],
      speed: [8, 15],
      angle: 5,
    },
  },

  // 13: 雾青浅绿 - Vortex swirl
  13: {
    name: 'Gentle Vortex',
    duration: 450,
    effect: 'vortex',
    config: {
      rings: 10,
      colors: ['#8FBC8F', '#C8F0C8', '#B0D8B0'],
      rotationSpeed: 0.1,
      pullStrength: 0.8,
    },
  },

  // 14: 深绿薄荷 - Aurora borealis
  14: {
    name: 'Forest Aurora',
    duration: 500,
    effect: 'aurora',
    config: {
      bandCount: 5,
      colors: ['#2E7D32', '#4CAF50', '#6FBF73'],
      waveSpeed: 0.05,
      opacity: 0.6,
    },
  },

  // 15: 电光蓝紫 - Nebula cloud
  15: {
    name: 'Electric Nebula',
    duration: 450,
    effect: 'nebula',
    config: {
      cloudCount: 8,
      colors: ['#4B6CC2', '#738ED6', '#9BA8E0'],
      turbulence: 0.3,
      glowIntensity: 1.5,
    },
  },

  // 16: 绿松冰蓝 - Crystal formation
  16: {
    name: 'Ice Crystals',
    duration: 400,
    effect: 'crystal',
    config: {
      crystalCount: 25,
      colors: ['#40E0D0', '#AEE2FF', '#72ECE0'],
      growthSpeed: 0.08,
      maxScale: 3,
      rotation: true,
    },
  },
}

export function getCanvasTransition(themeIndex: number): CanvasTransitionEffect {
  return canvasTransitions[themeIndex] || canvasTransitions[0]
}
