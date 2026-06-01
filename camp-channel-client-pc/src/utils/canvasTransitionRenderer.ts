/**
 * Canvas Page Transition Renderer
 * Renders HTML-in-Canvas transitions for page navigation
 */

import { getCanvasTransition, type CanvasTransitionEffect } from './canvasTransitions'
import { useThemeStore } from '../stores/theme'

interface Particle {
  x: number
  y: number
  vx: number
  vy: number
  life: number
  maxLife: number
  size: number
  color: string
  rotation?: number
  rotationSpeed?: number
}

class CanvasTransitionRenderer {
  private canvas: HTMLCanvasElement | null = null
  private ctx: CanvasRenderingContext2D | null = null
  private animationId: number | null = null
  private particles: Particle[] = []
  private currentEffect: CanvasTransitionEffect | null = null
  private startTime: number = 0
  private isAnimating: boolean = false
  private onTransitionEnd: (() => void) | null = null

  constructor() {
    this.initCanvas()
  }

  private initCanvas() {
    this.canvas = document.createElement('canvas')
    this.canvas.id = 'page-transition-canvas'
    this.canvas.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      z-index: 9999;
      opacity: 0;
      transition: opacity 0.2s ease;
    `
    document.body.appendChild(this.canvas)

    const resize = () => {
      if (this.canvas) {
        this.canvas.width = window.innerWidth
        this.canvas.height = window.innerHeight
      }
    }
    resize()
    window.addEventListener('resize', resize)

    this.ctx = this.canvas.getContext('2d')
  }

  public async startTransition(onComplete?: () => void): Promise<void> {
    if (this.isAnimating) return

    const themeStore = useThemeStore()
    this.currentEffect = getCanvasTransition(themeStore.themeIndex)
    this.onTransitionEnd = onComplete || null
    this.isAnimating = true
    this.startTime = performance.now()

    // Show canvas
    if (this.canvas) {
      this.canvas.style.opacity = '1'
    }

    // Initialize particles based on effect type
    this.initializeParticles()

    // Start animation
    this.animate()

    // Auto-end after duration
    setTimeout(() => {
      this.endTransition()
    }, this.currentEffect.duration)
  }

  private initializeParticles() {
    if (!this.currentEffect || !this.canvas) return

    const config = this.currentEffect.config || {}
    const width = this.canvas.width
    const height = this.canvas.height

    switch (this.currentEffect.effect) {
      case 'particles':
        this.initParticleEffect(config, width, height)
        break
      case 'waves':
        this.initWaveEffect(config, width, height)
        break
      case 'pixelate':
        this.initPixelateEffect(config, width, height)
        break
      case 'shatter':
        this.initShatterEffect(config, width, height)
        break
      case 'fireworks':
        this.initFireworksEffect(config, width, height)
        break
      case 'spiral':
        this.initSpiralEffect(config, width, height)
        break
      case 'matrix':
        this.initMatrixEffect(config, width, height)
        break
      case 'snow':
        this.initSnowEffect(config, width, height)
        break
      case 'rain':
        this.initRainEffect(config, width, height)
        break
      case 'crystal':
        this.initCrystalEffect(config, width, height)
        break
      default:
        this.initParticleEffect(config, width, height)
    }
  }

  private initParticleEffect(config: any, width: number, height: number) {
    const count = config.particleCount || 80
    const colors = config.colors || ['#7C9FCB']
    const sizeRange = config.size || [3, 8]
    const speedRange = config.speed || [2, 5]

    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: Math.random() * width,
        y: -Math.random() * height,
        vx: (Math.random() - 0.5) * speedRange[1],
        vy: Math.random() * speedRange[1] + speedRange[0],
        life: 0,
        maxLife: 100 + Math.random() * 100,
        size: Math.random() * (sizeRange[1] - sizeRange[0]) + sizeRange[0],
        color: colors[Math.floor(Math.random() * colors.length)],
        rotation: Math.random() * Math.PI * 2,
        rotationSpeed: (Math.random() - 0.5) * 0.1,
      })
    }
  }

  private initWaveEffect(config: any, width: number, height: number) {
    this.particles = []
  }

  private initPixelateEffect(config: any, width: number, height: number) {
    const pixelSize = config.pixelSize || 15
    const cols = Math.ceil(width / pixelSize)
    const rows = Math.ceil(height / pixelSize)

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        this.particles.push({
          x: col * pixelSize,
          y: row * pixelSize,
          vx: (Math.random() - 0.5) * 10,
          vy: (Math.random() - 0.5) * 10,
          life: 0,
          maxLife: 100,
          size: pixelSize,
          color: '#E84855',
        })
      }
    }
  }

  private initShatterEffect(config: any, width: number, height: number) {
    const count = config.shardCount || 60
    const colors = config.colors || ['#A0D2DB']

    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count
      const distance = Math.random() * 100
      this.particles.push({
        x: width / 2 + Math.cos(angle) * distance,
        y: height / 2 + Math.sin(angle) * distance,
        vx: Math.cos(angle) * (5 + Math.random() * 5),
        vy: Math.sin(angle) * (5 + Math.random() * 5),
        life: 0,
        maxLife: 100,
        size: 20 + Math.random() * 30,
        color: colors[Math.floor(Math.random() * colors.length)],
        rotation: Math.random() * Math.PI * 2,
        rotationSpeed: (Math.random() - 0.5) * 0.2,
      })
    }
  }

  private initFireworksEffect(config: any, width: number, height: number) {
    const count = config.fireworkCount || 12
    const colors = config.colors || ['#3B7A6B']

    for (let i = 0; i < count; i++) {
      setTimeout(() => {
        const x = Math.random() * width
        const y = Math.random() * height * 0.5
        this.createFireworkExplosion(x, y, colors)
      }, i * 100)
    }
  }

  private createFireworkExplosion(x: number, y: number, colors: string[]) {
    const particleCount = 40
    for (let i = 0; i < particleCount; i++) {
      const angle = (Math.PI * 2 * i) / particleCount
      const speed = 3 + Math.random() * 4
      this.particles.push({
        x,
        y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 0,
        maxLife: 60 + Math.random() * 40,
        size: 3 + Math.random() * 3,
        color: colors[Math.floor(Math.random() * colors.length)],
      })
    }
  }

  private initSpiralEffect(config: any, width: number, height: number) {
    const arms = config.spiralArms || 6
    const colors = config.colors || ['#6BCB9E']

    for (let arm = 0; arm < arms; arm++) {
      const baseAngle = (Math.PI * 2 * arm) / arms
      for (let i = 0; i < 50; i++) {
        const radius = i * 5
        const angle = baseAngle + i * 0.1
        this.particles.push({
          x: width / 2 + Math.cos(angle) * radius,
          y: height / 2 + Math.sin(angle) * radius,
          vx: 0,
          vy: 0,
          life: 0,
          maxLife: 100,
          size: 4,
          color: colors[arm % colors.length],
        })
      }
    }
  }

  private initMatrixEffect(config: any, width: number, height: number) {
    const columns = config.columnCount || 30
    const colWidth = width / columns

    for (let i = 0; i < columns; i++) {
      this.particles.push({
        x: i * colWidth,
        y: -Math.random() * height,
        vx: 0,
        vy: 5 + Math.random() * 5,
        life: 0,
        maxLife: 200,
        size: 15,
        color: '#39FF14',
      })
    }
  }

  private initSnowEffect(config: any, width: number, height: number) {
    const count = config.flakeCount || 100
    const colors = config.colors || ['#FF7F7F']
    const sizeRange = config.size || [2, 6]
    const speedRange = config.fallSpeed || [1, 3]

    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: Math.random() * width,
        y: -Math.random() * height,
        vx: (Math.random() - 0.5) * 0.5,
        vy: Math.random() * (speedRange[1] - speedRange[0]) + speedRange[0],
        life: 0,
        maxLife: 300,
        size: Math.random() * (sizeRange[1] - sizeRange[0]) + sizeRange[0],
        color: colors[Math.floor(Math.random() * colors.length)],
      })
    }
  }

  private initRainEffect(config: any, width: number, height: number) {
    const count = config.dropCount || 80
    const colors = config.colors || ['#87CEEB']
    const lengthRange = config.length || [15, 30]
    const speedRange = config.speed || [8, 15]

    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: Math.random() * width,
        y: -Math.random() * height,
        vx: 2,
        vy: Math.random() * (speedRange[1] - speedRange[0]) + speedRange[0],
        life: 0,
        maxLife: 200,
        size: Math.random() * (lengthRange[1] - lengthRange[0]) + lengthRange[0],
        color: colors[Math.floor(Math.random() * colors.length)],
      })
    }
  }

  private initCrystalEffect(config: any, width: number, height: number) {
    const count = config.crystalCount || 25
    const colors = config.colors || ['#40E0D0']

    for (let i = 0; i < count; i++) {
      this.particles.push({
        x: Math.random() * width,
        y: Math.random() * height,
        vx: 0,
        vy: 0,
        life: 0,
        maxLife: 100,
        size: 10 + Math.random() * 20,
        color: colors[Math.floor(Math.random() * colors.length)],
        rotation: Math.random() * Math.PI * 2,
        rotationSpeed: (Math.random() - 0.5) * 0.05,
      })
    }
  }

  private animate() {
    if (!this.isAnimating || !this.ctx || !this.canvas) return

    const elapsed = performance.now() - this.startTime
    const progress = Math.min(elapsed / (this.currentEffect?.duration || 1000), 1)

    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)

    // Render based on effect type
    this.renderEffect(progress)

    this.animationId = requestAnimationFrame(() => this.animate())
  }

  private renderEffect(progress: number) {
    if (!this.currentEffect || !this.ctx) return

    switch (this.currentEffect.effect) {
      case 'particles':
        this.renderParticles(progress)
        break
      case 'waves':
        this.renderWaves(progress)
        break
      case 'pixelate':
        this.renderPixelate(progress)
        break
      case 'shatter':
        this.renderShatter(progress)
        break
      case 'fireworks':
        this.renderFireworks(progress)
        break
      case 'spiral':
        this.renderSpiral(progress)
        break
      case 'matrix':
        this.renderMatrix(progress)
        break
      case 'snow':
        this.renderSnow(progress)
        break
      case 'rain':
        this.renderRain(progress)
        break
      case 'crystal':
        this.renderCrystals(progress)
        break
      default:
        this.renderParticles(progress)
    }
  }

  private renderParticles(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference
    
    this.particles.forEach((p) => {
      p.x += p.vx
      p.y += p.vy
      p.life++

      if (p.rotation !== undefined && p.rotationSpeed) {
        p.rotation += p.rotationSpeed
      }

      const alpha = 1 - p.life / p.maxLife
      ctx.save()
      ctx.globalAlpha = alpha
      ctx.translate(p.x, p.y)
      if (p.rotation) ctx.rotate(p.rotation)
      ctx.fillStyle = p.color
      ctx.beginPath()
      ctx.arc(0, 0, p.size, 0, Math.PI * 2)
      ctx.fill()
      ctx.restore()
    })
  }

  private renderWaves(progress: number) {
    if (!this.ctx || !this.canvas) return

    const config = this.currentEffect?.config || {}
    const colors = config.colors || ['#4A9BD9']
    const waveCount = config.waveCount || 5
    const amplitude = config.amplitude || 50

    for (let i = 0; i < waveCount; i++) {
      const offset = (i / waveCount) * Math.PI * 2
      const y = this.canvas.height / 2 + Math.sin(progress * Math.PI * 2 + offset) * amplitude

      this.ctx.strokeStyle = colors[i % colors.length]
      this.ctx.lineWidth = 3
      this.ctx.beginPath()
      this.ctx.moveTo(0, y)

      for (let x = 0; x <= this.canvas.width; x += 10) {
        const waveY = y + Math.sin((x * config.frequency) + progress * Math.PI * 4) * amplitude * 0.5
        this.ctx.lineTo(x, waveY)
      }

      this.ctx.stroke()
    }
  }

  private renderPixelate(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference
    const fadeOut = progress > 0.5
    const alpha = fadeOut ? 1 - (progress - 0.5) * 2 : progress * 2

    this.particles.forEach((p) => {
      if (fadeOut) {
        p.x += p.vx * (progress - 0.5) * 2
        p.y += p.vy * (progress - 0.5) * 2
      }

      ctx.save()
      ctx.globalAlpha = alpha
      ctx.fillStyle = p.color
      ctx.fillRect(p.x, p.y, p.size, p.size)
      ctx.restore()
    })
  }

  private renderShatter(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference

    this.particles.forEach((p) => {
      p.x += p.vx * progress
      p.y += p.vy * progress
      if (p.rotation !== undefined && p.rotationSpeed) {
        p.rotation += p.rotationSpeed
      }

      const alpha = 1 - progress
      ctx.save()
      ctx.globalAlpha = alpha
      ctx.translate(p.x, p.y)
      if (p.rotation) ctx.rotate(p.rotation)
      ctx.fillStyle = p.color
      ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size)
      ctx.restore()
    })
  }

  private renderFireworks(progress: number) {
    this.renderParticles(progress)
  }

  private renderSpiral(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference
    const config = this.currentEffect?.config || {}
    const rotationSpeed = config.rotationSpeed || 0.1

    this.particles.forEach((p, index) => {
      const expansion = 1 + progress * (config.expansionRate || 1.2)

      ctx.save()
      ctx.globalAlpha = 1 - progress * 0.5
      ctx.fillStyle = p.color
      ctx.beginPath()
      ctx.arc(p.x, p.y, p.size * expansion, 0, Math.PI * 2)
      ctx.fill()
      ctx.restore()
    })
  }

  private renderMatrix(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference
    const canvas = this.canvas
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*'

    this.particles.forEach((p) => {
      p.y += p.vy
      if (p.y > (canvas?.height || 0)) {
        p.y = -20
      }

      const char = chars[Math.floor(Math.random() * chars.length)]
      ctx.save()
      ctx.globalAlpha = 0.8
      ctx.fillStyle = p.color
      ctx.font = `${p.size}px monospace`
      ctx.fillText(char, p.x, p.y)
      ctx.restore()
    })
  }

  private renderSnow(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference
    const canvas = this.canvas

    this.particles.forEach((p) => {
      p.x += p.vx + Math.sin(p.life * 0.05) * 0.5
      p.y += p.vy
      p.life++

      if (p.y > (canvas?.height || 0)) {
        p.y = -10
        p.x = Math.random() * (canvas?.width || 0)
      }

      ctx.save()
      ctx.globalAlpha = 0.8
      ctx.fillStyle = p.color
      ctx.beginPath()
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
      ctx.fill()
      ctx.restore()
    })
  }

  private renderRain(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference
    const canvas = this.canvas

    this.particles.forEach((p) => {
      p.x += p.vx
      p.y += p.vy

      if (p.y > (canvas?.height || 0)) {
        p.y = -p.size
        p.x = Math.random() * (canvas?.width || 0)
      }

      ctx.save()
      ctx.globalAlpha = 0.6
      ctx.strokeStyle = p.color
      ctx.lineWidth = 2
      ctx.beginPath()
      ctx.moveTo(p.x, p.y)
      ctx.lineTo(p.x + p.vx * 2, p.y + p.size)
      ctx.stroke()
      ctx.restore()
    })
  }

  private renderCrystals(progress: number) {
    if (!this.ctx) return

    const ctx = this.ctx // Capture non-null reference
    const config = this.currentEffect?.config || {}
    const growthSpeed = config.growthSpeed || 0.08
    const maxScale = config.maxScale || 3

    this.particles.forEach((p) => {
      if (p.rotation !== undefined && p.rotationSpeed && config.rotation) {
        p.rotation += p.rotationSpeed
      }

      const scale = Math.min(1 + progress * growthSpeed * 10, maxScale)
      const alpha = Math.min(progress * 2, 1) * (1 - progress * 0.3)

      ctx.save()
      ctx.globalAlpha = alpha
      ctx.translate(p.x, p.y)
      if (p.rotation) ctx.rotate(p.rotation)
      ctx.fillStyle = p.color

      // Draw crystal shape (hexagon)
      ctx.beginPath()
      for (let i = 0; i < 6; i++) {
        const angle = (Math.PI / 3) * i
        const x = Math.cos(angle) * p.size * scale
        const y = Math.sin(angle) * p.size * scale
        if (i === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      }
      ctx.closePath()
      ctx.fill()
      ctx.restore()
    })
  }

  private endTransition() {
    this.isAnimating = false

    if (this.animationId) {
      cancelAnimationFrame(this.animationId)
      this.animationId = null
    }

    // Fade out canvas
    if (this.canvas) {
      this.canvas.style.opacity = '0'
    }

    // Clear particles
    this.particles = []

    // Call callback
    if (this.onTransitionEnd) {
      this.onTransitionEnd()
    }

    setTimeout(() => {
      if (this.ctx) {
        this.ctx.clearRect(0, 0, this.canvas?.width || 0, this.canvas?.height || 0)
      }
    }, 200)
  }
}

// Singleton instance
let canvasRenderer: CanvasTransitionRenderer | null = null

export function initCanvasTransitions(): void {
  if (!canvasRenderer) {
    canvasRenderer = new CanvasTransitionRenderer()
  }
}

export function triggerCanvasTransition(onComplete?: () => void): void {
  if (!canvasRenderer) {
    initCanvasTransitions()
  }
  canvasRenderer?.startTransition(onComplete)
}
