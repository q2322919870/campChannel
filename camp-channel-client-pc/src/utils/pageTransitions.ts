/**
 * Theme-based Page Transition Effects
 * Each theme has unique page transition animation
 */

export interface PageTransitionEffect {
  name: string
  duration: number // milliseconds
  easing: string
  effect: 'fade' | 'slide' | 'zoom' | 'rotate' | 'flip' | 'scale' | 'blur' | 'morph' | 'wave' | 'elastic'
  direction?: 'left' | 'right' | 'up' | 'down' | 'in' | 'out'
  additionalProps?: Record<string, any>
}

export const pageTransitions: Record<number, PageTransitionEffect> = {
  // 0: 雾蓝樱粉 - Elegant fade with soft scale
  0: {
    name: 'Sakura Fade',
    duration: 250,
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
    effect: 'fade',
    additionalProps: {
      scale: [0.95, 1],
      opacity: [0, 1],
    },
  },

  // 1: 湖蓝淡粉 - Smooth slide from right
  1: {
    name: 'Water Slide',
    duration: 200,
    easing: 'cubic-bezier(0.25, 0.46, 0.45, 0.94)',
    effect: 'slide',
    direction: 'right',
  },

  // 2: 鼠尾草淡黄 - Gentle zoom in
  2: {
    name: 'Nature Zoom',
    duration: 250,
    easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    effect: 'zoom',
    additionalProps: {
      scale: [0.8, 1],
    },
  },

  // 3: 薄荷孔雀绿 - Fresh rotate entrance
  3: {
    name: 'Mint Rotate',
    duration: 250,
    easing: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
    effect: 'rotate',
    direction: 'in',
    additionalProps: {
      rotate: [-15, 0],
    },
  },

  // 4: 玫红雪白 - Bold flip transition
  4: {
    name: 'Rose Flip',
    duration: 300,
    easing: 'cubic-bezier(0.7, 0, 0.3, 1)',
    effect: 'flip',
    direction: 'left',
  },

  // 5: 浅蓝薄荷 - Soft scale up
  5: {
    name: 'Mist Scale',
    duration: 200,
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
    effect: 'scale',
    additionalProps: {
      scale: [0.9, 1],
      opacity: [0.5, 1],
    },
  },

  // 6: 夜紫橙金 - Magic blur reveal
  6: {
    name: 'Magic Blur',
    duration: 250,
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
    effect: 'blur',
    additionalProps: {
      blur: [10, 0],
      opacity: [0, 1],
    },
  },

  // 7: 深蓝柔粉 - Deep slide up
  7: {
    name: 'Deep Rise',
    duration: 200,
    easing: 'cubic-bezier(0.25, 0.46, 0.45, 0.94)',
    effect: 'slide',
    direction: 'up',
  },

  // 8: 青绿奶杏 - Organic morph
  8: {
    name: 'Organic Morph',
    duration: 300,
    easing: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
    effect: 'morph',
    additionalProps: {
      borderRadius: ['50%', '0%'],
      scale: [1.1, 1],
    },
  },

  // 9: 薄荷橙金 - Energy wave
  9: {
    name: 'Energy Wave',
    duration: 250,
    easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    effect: 'wave',
    direction: 'left',
  },

  // 10: 荧光水绿 - Neon elastic bounce
  10: {
    name: 'Neon Bounce',
    duration: 300,
    easing: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
    effect: 'elastic',
    additionalProps: {
      scale: [0.5, 1.2, 0.9, 1],
    },
  },

  // 11: 珊瑚玫瑰雾 - Romantic fade with drift
  11: {
    name: 'Romantic Drift',
    duration: 250,
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
    effect: 'fade',
    additionalProps: {
      translateX: [50, 0],
      opacity: [0, 1],
    },
  },

  // 12: 天蓝奶黄 - Sky float down
  12: {
    name: 'Sky Float',
    duration: 250,
    easing: 'cubic-bezier(0.25, 0.46, 0.45, 0.94)',
    effect: 'slide',
    direction: 'down',
  },

  // 13: 雾青浅绿 - Gentle wave ripple
  13: {
    name: 'Gentle Ripple',
    duration: 250,
    easing: 'cubic-bezier(0.4, 0, 0.2, 1)',
    effect: 'wave',
    direction: 'right',
  },

  // 14: 深绿薄荷 - Forest grow
  14: {
    name: 'Forest Grow',
    duration: 300,
    easing: 'cubic-bezier(0.34, 1.56, 0.64, 1)',
    effect: 'scale',
    additionalProps: {
      scale: [0, 1],
      opacity: [0, 1],
    },
  },

  // 15: 电光蓝紫 - Electric flash
  15: {
    name: 'Electric Flash',
    duration: 200,
    easing: 'cubic-bezier(0.7, 0, 0.3, 1)',
    effect: 'fade',
    additionalProps: {
      opacity: [0, 1],
      filter: ['brightness(2) blur(5px)', 'brightness(1) blur(0)'],
    },
  },

  // 16: 绿松冰蓝 - Ice crystal formation
  16: {
    name: 'Ice Crystal',
    duration: 250,
    easing: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
    effect: 'zoom',
    additionalProps: {
      scale: [0.3, 1],
      rotate: [180, 0],
      opacity: [0, 1],
    },
  },
}

export function getPageTransition(themeIndex: number): PageTransitionEffect {
  return pageTransitions[themeIndex] || pageTransitions[0]
}
