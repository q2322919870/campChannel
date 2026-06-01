/**
 * Hybrid Page Transition System
 * Combines CSS transitions + Canvas effects for enhanced visual impact
 */

import { getPageTransition, type PageTransitionEffect } from './pageTransitions'
import { getCanvasTransition, type CanvasTransitionEffect } from './canvasTransitions'
import { useThemeStore } from '../stores/theme'

export interface HybridTransitionConfig {
  cssEffect: PageTransitionEffect
  canvasEffect: CanvasTransitionEffect
  staggerDelay: number // Delay between CSS and Canvas (ms)
}

export function getHybridTransition(themeIndex: number): HybridTransitionConfig {
  const cssEffect = getPageTransition(themeIndex)
  const canvasEffect = getCanvasTransition(themeIndex)
  
  return {
    cssEffect,
    canvasEffect,
    staggerDelay: 50, // Start canvas 50ms after CSS starts
  }
}
