/**
 * Cursor Effect Renderer
 * Handles click effects and movement trails based on theme
 */

import { getCursorEffect, type CursorEffect } from './cursorEffects'

interface TrailParticle {
  x: number
  y: number
  life: number
  maxLife: number
  size: number
  color: string
  vx?: number
  vy?: number
  angle?: number
}

class CursorEffectRenderer {
  private canvas: HTMLCanvasElement | null = null
  private ctx: CanvasRenderingContext2D | null = null
  private particles: TrailParticle[] = []
  private animationId: number | null = null
  private currentEffect: CursorEffect | null = null
  private lastMouseX = 0
  private lastMouseY = 0
  private mouseSpeed = 0

  constructor() {
    this.initCanvas()
    this.bindEvents()
  }

  private initCanvas() {
    this.canvas = document.createElement('canvas')
    this.canvas.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      z-index: 9999;
    `
    document.body.appendChild(this.canvas)
    
    this.ctx = this.canvas.getContext('2d')
    this.resizeCanvas()
    
    window.addEventListener('resize', () => this.resizeCanvas())
  }

  private resizeCanvas() {
    if (!this.canvas || !this.ctx) return
    this.canvas.width = window.innerWidth
    this.canvas.height = window.innerHeight
  }

  private bindEvents() {
    document.addEventListener('mousemove', (e) => this.handleMouseMove(e))
    document.addEventListener('click', (e) => this.handleClick(e))
  }

  private handleMouseMove(e: MouseEvent) {
    if (!this.currentEffect || this.currentEffect.trailEffect === 'none') return

    const dx = e.clientX - this.lastMouseX
    const dy = e.clientY - this.lastMouseY
    this.mouseSpeed = Math.sqrt(dx * dx + dy * dy)

    this.lastMouseX = e.clientX
    this.lastMouseY = e.clientY

    // Add trail particles based on effect type
    switch (this.currentEffect.trailEffect) {
      case 'dots':
        this.addDotTrail(e.clientX, e.clientY)
        break
      case 'line':
        this.addLineTrail(e.clientX, e.clientY)
        break
      case 'particles':
        this.addParticleTrail(e.clientX, e.clientY, dx, dy)
        break
      case 'glow':
        this.addGlowTrail(e.clientX, e.clientY)
        break
      case 'spiral':
        this.addSpiralTrail(e.clientX, e.clientY, dx, dy)
        break
    }

    if (!this.animationId) {
      this.animate()
    }
  }

  private handleClick(e: MouseEvent) {
    if (!this.currentEffect || this.currentEffect.clickEffect === 'none') return

    switch (this.currentEffect.clickEffect) {
      case 'ripple':
        this.createRippleEffect(e.clientX, e.clientY)
        break
      case 'sparkle':
        this.createSparkleEffect(e.clientX, e.clientY)
        break
      case 'burst':
        this.createBurstEffect(e.clientX, e.clientY)
        break
      case 'wave':
        this.createWaveEffect(e.clientX, e.clientY)
        break
      case 'pulse':
        this.createPulseEffect(e.clientX, e.clientY)
        break
      case 'glow':
        this.createGlowEffect(e.clientX, e.clientY)
        break
      case 'particle':
        this.createParticleEffect(e.clientX, e.clientY)
        break
    }
  }

  private addDotTrail(x: number, y: number) {
    if (!this.currentEffect) return
    this.particles.push({
      x,
      y,
      life: 30,
      maxLife: 30,
      size: this.currentEffect.trailSize || 4,
      color: this.currentEffect.trailColor || '#fff',
    })
  }

  private addLineTrail(x: number, y: number) {
    if (!this.currentEffect || this.mouseSpeed < 2) return
    this.particles.push({
      x,
      y,
      life: 20,
      maxLife: 20,
      size: this.currentEffect.trailSize || 3,
      color: this.currentEffect.trailColor || '#fff',
    })
  }

  private addParticleTrail(x: number, y: number, dx: number, dy: number) {
    if (!this.currentEffect || this.mouseSpeed < 3) return
    
    const count = Math.min(Math.floor(this.mouseSpeed / 5), 3)
    for (let i = 0; i < count; i++) {
      const angle = Math.random() * Math.PI * 2
      const speed = Math.random() * 2
      this.particles.push({
        x,
        y,
        life: 40,
        maxLife: 40,
        size: Math.random() * (this.currentEffect.trailSize || 5) + 2,
        color: this.currentEffect.trailColor || '#fff',
        vx: Math.cos(angle) * speed - dx * 0.1,
        vy: Math.sin(angle) * speed - dy * 0.1,
      })
    }
  }

  private addGlowTrail(x: number, y: number) {
    if (!this.currentEffect) return
    this.particles.push({
      x,
      y,
      life: 25,
      maxLife: 25,
      size: (this.currentEffect.trailSize || 6) * 2,
      color: this.currentEffect.trailColor || '#fff',
    })
  }

  private addSpiralTrail(x: number, y: number, dx: number, dy: number) {
    if (!this.currentEffect || this.mouseSpeed < 2) return
    
    const angle = Math.atan2(dy, dx) + Math.PI / 2
    const offset = 10
    this.particles.push({
      x: x + Math.cos(angle) * offset,
      y: y + Math.sin(angle) * offset,
      life: 35,
      maxLife: 35,
      size: this.currentEffect.trailSize || 5,
      color: this.currentEffect.trailColor || '#fff',
      angle: angle,
    })
  }

  private createRippleEffect(x: number, y: number) {
    if (!this.currentEffect) return
    const color = this.currentEffect.clickColor || this.currentEffect.trailColor || '#fff'
    
    for (let i = 0; i < 3; i++) {
      setTimeout(() => {
        this.particles.push({
          x,
          y,
          life: 40,
          maxLife: 40,
          size: 5 + i * 15,
          color,
        })
      }, i * 100)
    }
  }

  private createSparkleEffect(x: number, y: number) {
    if (!this.currentEffect) return
    const color = this.currentEffect.clickColor || this.currentEffect.trailColor || '#fff'
    
    for (let i = 0; i < 12; i++) {
      const angle = (Math.PI * 2 * i) / 12
      const speed = 3 + Math.random() * 2
      this.particles.push({
        x,
        y,
        life: 30,
        maxLife: 30,
        size: Math.random() * 4 + 2,
        color,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
      })
    }
  }

  private createBurstEffect(x: number, y: number) {
    if (!this.currentEffect) return
    const color = this.currentEffect.clickColor || this.currentEffect.trailColor || '#fff'
    
    for (let i = 0; i < 20; i++) {
      const angle = Math.random() * Math.PI * 2
      const speed = 2 + Math.random() * 4
      this.particles.push({
        x,
        y,
        life: 35,
        maxLife: 35,
        size: Math.random() * 5 + 2,
        color,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
      })
    }
  }

  private createWaveEffect(x: number, y: number) {
    if (!this.currentEffect) return
    const color = this.currentEffect.clickColor || this.currentEffect.trailColor || '#fff'
    
    for (let ring = 0; ring < 4; ring++) {
      setTimeout(() => {
        for (let i = 0; i < 8; i++) {
          const angle = (Math.PI * 2 * i) / 8
          const radius = 20 + ring * 15
          this.particles.push({
            x: x + Math.cos(angle) * radius,
            y: y + Math.sin(angle) * radius,
            life: 30,
            maxLife: 30,
            size: 4,
            color,
          })
        }
      }, ring * 80)
    }
  }

  private createPulseEffect(x: number, y: number) {
    if (!this.currentEffect) return
    const color = this.currentEffect.clickColor || this.currentEffect.trailColor || '#fff'
    
    for (let i = 0; i < 8; i++) {
      const angle = (Math.PI * 2 * i) / 8
      this.particles.push({
        x,
        y,
        life: 40,
        maxLife: 40,
        size: 6,
        color,
        vx: Math.cos(angle) * 3,
        vy: Math.sin(angle) * 3,
      })
    }
  }

  private createGlowEffect(x: number, y: number) {
    if (!this.currentEffect) return
    const color = this.currentEffect.clickColor || this.currentEffect.trailColor || '#fff'
    
    this.particles.push({
      x,
      y,
      life: 50,
      maxLife: 50,
      size: 40,
      color,
    })
  }

  private createParticleEffect(x: number, y: number) {
    if (!this.currentEffect) return
    const color = this.currentEffect.clickColor || this.currentEffect.trailColor || '#fff'
    
    for (let i = 0; i < 30; i++) {
      const angle = Math.random() * Math.PI * 2
      const speed = 1 + Math.random() * 5
      const life = 30 + Math.random() * 20
      this.particles.push({
        x,
        y,
        life,
        maxLife: life,
        size: Math.random() * 4 + 1,
        color,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
      })
    }
  }

  private animate() {
    if (!this.ctx || !this.canvas) return

    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)

    // Update and draw particles
    this.particles = this.particles.filter((p) => {
      p.life--
      
      // Update position if velocity exists
      if (p.vx !== undefined && p.vy !== undefined) {
        p.x += p.vx
        p.y += p.vy
        p.vx *= 0.98 // friction
        p.vy *= 0.98
      }

      const alpha = p.life / p.maxLife
      const size = p.size * alpha

      if (!this.ctx) return false

      this.ctx.save()
      this.ctx.globalAlpha = alpha

      if (this.currentEffect?.trailEffect === 'glow' || this.currentEffect?.clickEffect === 'glow') {
        // Glow effect
        const gradient = this.ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, size)
        gradient.addColorStop(0, p.color)
        gradient.addColorStop(1, 'transparent')
        this.ctx.fillStyle = gradient
        this.ctx.beginPath()
        this.ctx.arc(p.x, p.y, size, 0, Math.PI * 2)
        this.ctx.fill()
      } else {
        // Normal particle
        this.ctx.fillStyle = p.color
        this.ctx.beginPath()
        this.ctx.arc(p.x, p.y, size, 0, Math.PI * 2)
        this.ctx.fill()
      }

      this.ctx.restore()

      return p.life > 0
    })

    if (this.particles.length > 0) {
      this.animationId = requestAnimationFrame(() => this.animate())
    } else {
      this.animationId = null
    }
  }

  public setTheme(themeIndex: number) {
    this.currentEffect = getCursorEffect(themeIndex)
    
    // Apply custom cursors
    if (this.currentEffect) {
      // Default cursor
      document.body.style.cursor = this.currentEffect.cursor
      
      // Pointer cursor for clickable elements
      const pointerStyle = document.getElementById('cursor-pointer-style') || document.createElement('style')
      pointerStyle.id = 'cursor-pointer-style'
      pointerStyle.textContent = `
        a:hover, button:hover, [role="button"]:hover, 
        .clickable:hover, input[type="submit"]:hover,
        input[type="button"]:hover, label:hover {
          cursor: ${this.currentEffect.pointerCursor} !important;
        }
      `
      if (!document.getElementById('cursor-pointer-style')) {
        document.head.appendChild(pointerStyle)
      }
      
      // Text cursor for input fields
      const textStyle = document.getElementById('cursor-text-style') || document.createElement('style')
      textStyle.id = 'cursor-text-style'
      textStyle.textContent = `
        input[type="text"]:not([disabled]),
        input[type="password"],
        input[type="email"],
        input[type="search"],
        input[type="tel"],
        input[type="url"],
        textarea:not([disabled]),
        [contenteditable="true"] {
          cursor: ${this.currentEffect.textCursor} !important;
        }
      `
      if (!document.getElementById('cursor-text-style')) {
        document.head.appendChild(textStyle)
      }
    }
  }

  public destroy() {
    if (this.canvas) {
      this.canvas.remove()
    }
    if (this.animationId) {
      cancelAnimationFrame(this.animationId)
    }
    this.particles = []
  }
}

// Singleton instance
let instance: CursorEffectRenderer | null = null

export function initCursorEffects() {
  if (!instance) {
    instance = new CursorEffectRenderer()
  }
  return instance
}

export function setCursorTheme(themeIndex: number) {
  if (!instance) {
    instance = initCursorEffects()
  }
  instance.setTheme(themeIndex)
}

export function destroyCursorEffects() {
  if (instance) {
    instance.destroy()
    instance = null
  }
}
