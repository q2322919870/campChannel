/**
 * Page Transition Manager
 * Applies theme-specific transitions when navigating between pages
 */

import { getPageTransition, type PageTransitionEffect } from './pageTransitions'
import { useThemeStore } from '../stores/theme'

class PageTransitionManager {
  private currentTransition: PageTransitionEffect | null = null
  private isAnimating = false

  constructor() {
    this.bindRouterEvents()
  }

  private bindRouterEvents() {
    // Listen for Vue Router navigation events
    const router = (window as any).__VUE_ROUTER__
    if (!router) {
      console.warn('Vue Router not found. Page transitions will be disabled.')
      return
    }

    // Before navigation starts
    router.beforeEach((to: any, from: any, next: any) => {
      if (this.isAnimating) {
        next(false)
        return
      }

      const themeStore = useThemeStore()
      this.currentTransition = getPageTransition(themeStore.themeIndex)
      
      // Apply enter animation to target page
      this.applyEnterAnimation(to.fullPath).then(() => {
        next()
      })
    })

    // After navigation completes
    router.afterEach((to: any, from: any) => {
      // Apply exit animation to previous page
      if (from.fullPath) {
        this.applyExitAnimation(from.fullPath)
      }
    })
  }

  private async applyEnterAnimation(targetPath: string): Promise<void> {
    if (!this.currentTransition || this.isAnimating) return

    this.isAnimating = true
    const effect = this.currentTransition
    const element = document.getElementById('app-content') || document.body

    // Create animation based on effect type
    switch (effect.effect) {
      case 'fade':
        await this.fadeIn(element, effect)
        break
      case 'slide':
        await this.slideIn(element, effect)
        break
      case 'zoom':
        await this.zoomIn(element, effect)
        break
      case 'rotate':
        await this.rotateIn(element, effect)
        break
      case 'flip':
        await this.flipIn(element, effect)
        break
      case 'scale':
        await this.scaleIn(element, effect)
        break
      case 'blur':
        await this.blurIn(element, effect)
        break
      case 'morph':
        await this.morphIn(element, effect)
        break
      case 'wave':
        await this.waveIn(element, effect)
        break
      case 'elastic':
        await this.elasticIn(element, effect)
        break
      default:
        await this.fadeIn(element, effect)
    }

    this.isAnimating = false
  }

  private async applyExitAnimation(previousPath: string): Promise<void> {
    if (!this.currentTransition) return

    const element = document.getElementById('app-content') || document.body
    
    // Quick fade out for exit
    element.style.transition = `opacity ${this.currentTransition.duration / 2}ms ${this.currentTransition.easing}`
    element.style.opacity = '0'
    
    await this.wait(this.currentTransition.duration / 2)
    element.style.opacity = ''
    element.style.transition = ''
  }

  private async fadeIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const props = effect.additionalProps || {}
    element.style.opacity = '0'
    element.style.transform = `scale(${props.scale?.[0] || 1})`
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.opacity = '1'
    element.style.transform = `scale(${props.scale?.[1] || 1})`
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async slideIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
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
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.transform = 'translateX(0) translateY(0)'
    element.style.opacity = '1'
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async zoomIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const props = effect.additionalProps || {}
    const scale = props.scale?.[0] || 0.8
    const rotate = props.rotate?.[0] || 0
    
    element.style.transform = `scale(${scale}) rotate(${rotate}deg)`
    element.style.opacity = '0'
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.transform = 'scale(1) rotate(0deg)'
    element.style.opacity = '1'
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async rotateIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const props = effect.additionalProps || {}
    const rotate = props.rotate?.[0] || -15
    
    element.style.transform = `rotate(${rotate}deg) scale(0.9)`
    element.style.opacity = '0'
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.transform = 'rotate(0deg) scale(1)'
    element.style.opacity = '1'
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async flipIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const direction = effect.direction || 'left'
    const axis = direction === 'left' || direction === 'right' ? 'Y' : 'X'
    const angle = direction === 'left' || direction === 'up' ? 90 : -90
    
    element.style.transform = `rotate${axis}(${angle}deg)`
    element.style.opacity = '0'
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.transform = 'rotateY(0deg) rotateX(0deg)'
    element.style.opacity = '1'
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async scaleIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const props = effect.additionalProps || {}
    const scale = props.scale?.[0] || 0.9
    const opacity = props.opacity?.[0] || 0.5
    
    element.style.transform = `scale(${scale})`
    element.style.opacity = String(opacity)
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.transform = `scale(${props.scale?.[1] || 1})`
    element.style.opacity = String(props.opacity?.[1] || 1)
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async blurIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const props = effect.additionalProps || {}
    const blur = props.blur?.[0] || 10
    
    element.style.filter = `blur(${blur}px)`
    element.style.opacity = '0'
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.filter = `blur(${props.blur?.[1] || 0}px)`
    element.style.opacity = '1'
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async morphIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const props = effect.additionalProps || {}
    const borderRadius = props.borderRadius?.[0] || '50%'
    const scale = props.scale?.[0] || 1.1
    
    element.style.borderRadius = borderRadius
    element.style.transform = `scale(${scale})`
    element.style.opacity = '0'
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.borderRadius = props.borderRadius?.[1] || '0%'
    element.style.transform = `scale(${props.scale?.[1] || 1})`
    element.style.opacity = '1'
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async waveIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const direction = effect.direction || 'left'
    const sign = direction === 'left' || direction === 'up' ? -1 : 1
    
    element.style.transform = `translateX(${sign * 100}px) skewX(${sign * 10}deg)`
    element.style.opacity = '0'
    
    element.style.transition = `all ${effect.duration}ms ${effect.easing}`
    element.style.transform = 'translateX(0) skewX(0deg)'
    element.style.opacity = '1'
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private async elasticIn(element: HTMLElement, effect: PageTransitionEffect): Promise<void> {
    const props = effect.additionalProps || {}
    const scales = props.scale || [0.5, 1.2, 0.9, 1]
    
    element.style.transform = `scale(${scales[0]})`
    element.style.opacity = '0'
    
    element.style.transition = `transform ${effect.duration}ms ${effect.easing}, opacity ${effect.duration / 2}ms ease-out`
    element.style.opacity = '1'
    
    // Create elastic bounce effect
    const steps = scales.length
    const stepDuration = effect.duration / steps
    
    for (let i = 1; i < scales.length; i++) {
      setTimeout(() => {
        element.style.transform = `scale(${scales[i]})`
      }, i * stepDuration)
    }
    
    await this.wait(effect.duration)
    element.style.transition = ''
  }

  private wait(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  public forceTransition(): void {
    // Manually trigger transition (useful for testing)
    const themeStore = useThemeStore()
    this.currentTransition = getPageTransition(themeStore.themeIndex)
  }
}

// Singleton instance
let transitionManager: PageTransitionManager | null = null

export function initPageTransitions(): void {
  if (!transitionManager) {
    transitionManager = new PageTransitionManager()
  }
}

export function getTransitionManager(): PageTransitionManager | null {
  return transitionManager
}
