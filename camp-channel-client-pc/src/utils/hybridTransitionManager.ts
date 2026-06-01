/**
 * Hybrid Transition Manager
 * Coordinates CSS + Canvas transitions for maximum visual impact
 */

import { getHybridTransition, type HybridTransitionConfig } from './hybridTransitions'
import { useThemeStore } from '../stores/theme'
import { triggerCanvasTransition } from './canvasTransitionRenderer'

class HybridTransitionManager {
  private isAnimating = false
  private currentConfig: HybridTransitionConfig | null = null

  constructor() {
    this.bindRouterEvents()
  }

  private bindRouterEvents() {
    const router = (window as any).__VUE_ROUTER__
    if (!router) {
      console.warn('Vue Router not found. Hybrid transitions will be disabled.')
      return
    }

    // Before navigation starts
    router.beforeEach((to: any, from: any, next: any) => {
      if (this.isAnimating) {
        next(false)
        return
      }

      // Skip transition for same page or initial load
      if (!from.path || from.path === to.path) {
        next()
        return
      }

      const themeStore = useThemeStore()
      this.currentConfig = getHybridTransition(themeStore.themeIndex)
      
      // Start hybrid transition
      this.startHybridTransition(() => {
        next()
      })
    })
  }

  private async startHybridTransition(onComplete: () => void): Promise<void> {
    if (!this.currentConfig || this.isAnimating) return

    this.isAnimating = true
    const config = this.currentConfig
    const element = document.getElementById('app-content') || document.body

    // Phase 1: Apply CSS transition to page content
    this.applyCSSTransition(element, config.cssEffect)

    // Phase 2: Trigger canvas overlay after stagger delay
    setTimeout(() => {
      triggerCanvasTransition(() => {
        // Canvas animation complete
      })
    }, config.staggerDelay)

    // Wait for both animations to complete
    const maxDuration = Math.max(
      config.cssEffect.duration,
      config.canvasEffect.duration + config.staggerDelay
    )

    setTimeout(() => {
      this.cleanupCSSTransition(element)
      this.isAnimating = false
      onComplete()
    }, maxDuration)
  }

  private applyCSSTransition(element: HTMLElement, effect: any): void {
    const duration = effect.duration
    const easing = effect.easing
    
    // Reset any existing transitions
    element.style.transition = 'none'
    element.style.opacity = ''
    element.style.transform = ''
    element.style.filter = ''

    // Force reflow
    void element.offsetHeight

    // Apply initial state based on effect type
    switch (effect.effect) {
      case 'fade':
        const props = effect.additionalProps || {}
        element.style.opacity = '0'
        element.style.transform = `scale(${props.scale?.[0] || 1})`
        break

      case 'slide':
        const direction = effect.direction || 'right'
        let translateValue = '100%'
        
        switch (direction) {
          case 'left':
            translateValue = '-100%'
            break
          case 'up':
            translateValue = 'translateY(-100%)'
            break
          case 'down':
            translateValue = 'translateY(100%)'
            break
          default:
            translateValue = 'translateX(100%)'
        }
        
        element.style.transform = typeof translateValue === 'string' && translateValue.includes('translate') 
          ? translateValue 
          : `translateX(${translateValue})`
        element.style.opacity = '0'
        break

      case 'zoom':
        const zoomProps = effect.additionalProps || {}
        const scale = zoomProps.scale?.[0] || 0.8
        const rotate = zoomProps.rotate?.[0] || 0
        
        element.style.transform = `scale(${scale}) rotate(${rotate}deg)`
        element.style.opacity = '0'
        break

      case 'rotate':
        const rotateProps = effect.additionalProps || {}
        const rotateAngle = rotateProps.rotate?.[0] || -15
        
        element.style.transform = `rotate(${rotateAngle}deg) scale(0.9)`
        element.style.opacity = '0'
        break

      case 'flip':
        const flipDirection = effect.direction || 'left'
        const axis = flipDirection === 'left' || flipDirection === 'right' ? 'Y' : 'X'
        const angle = flipDirection === 'left' || flipDirection === 'up' ? 90 : -90
        
        element.style.transform = `rotate${axis}(${angle}deg)`
        element.style.opacity = '0'
        break

      case 'scale':
        const scaleProps = effect.additionalProps || {}
        const startScale = scaleProps.scale?.[0] || 0.9
        const startOpacity = scaleProps.opacity?.[0] || 0.5
        
        element.style.transform = `scale(${startScale})`
        element.style.opacity = String(startOpacity)
        break

      case 'blur':
        const blurProps = effect.additionalProps || {}
        const blur = blurProps.blur?.[0] || 10
        
        element.style.filter = `blur(${blur}px)`
        element.style.opacity = '0'
        break

      case 'morph':
        const morphProps = effect.additionalProps || {}
        const borderRadius = morphProps.borderRadius?.[0] || '50%'
        const morphScale = morphProps.scale?.[0] || 1.1
        
        element.style.borderRadius = borderRadius
        element.style.transform = `scale(${morphScale})`
        element.style.opacity = '0'
        break

      case 'wave':
        const waveDirection = effect.direction || 'left'
        const sign = waveDirection === 'left' || waveDirection === 'up' ? -1 : 1
        
        element.style.transform = `translateX(${sign * 100}px) skewX(${sign * 10}deg)`
        element.style.opacity = '0'
        break

      case 'elastic':
        const elasticProps = effect.additionalProps || {}
        const scales = elasticProps.scale || [0.5, 1.2, 0.9, 1]
        
        element.style.transform = `scale(${scales[0]})`
        element.style.opacity = '0'
        break

      default:
        element.style.opacity = '0'
        element.style.transform = 'scale(0.95)'
    }

    // Force another reflow
    void element.offsetHeight

    // Apply transition and final state
    element.style.transition = `all ${duration}ms ${easing}`
    
    // Set final state
    setTimeout(() => {
      element.style.opacity = '1'
      element.style.transform = 'translateX(0) translateY(0) scale(1) rotate(0deg)'
      element.style.filter = ''
      element.style.borderRadius = ''
    }, 50)
  }

  private cleanupCSSTransition(element: HTMLElement): void {
    // Remove inline styles after transition completes
    setTimeout(() => {
      element.style.transition = ''
      element.style.opacity = ''
      element.style.transform = ''
      element.style.filter = ''
      element.style.borderRadius = ''
    }, 300)
  }
}

// Singleton instance
let hybridManager: HybridTransitionManager | null = null

export function initHybridTransitions(): void {
  if (!hybridManager) {
    hybridManager = new HybridTransitionManager()
  }
}

export function getHybridManager(): HybridTransitionManager | null {
  return hybridManager
}
