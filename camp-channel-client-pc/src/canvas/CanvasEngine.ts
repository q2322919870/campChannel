import { ParticleSystem } from './ParticleSystem'
import { GlassEffect } from './GlassEffect'
import { ThemeRenderer } from './ThemeRenderer'

export interface ThemeColors {
  primary: string
  primaryLight: string
  accent: string
  bg: string
  card: string
  text: string
  textSecondary: string
  border: string
  gradientStart: string
  gradientEnd: string
  glowColor: string
}

export class CanvasEngine {
  private canvas: HTMLCanvasElement | null = null
  private ctx: CanvasRenderingContext2D | null = null
  private animationId: number = 0
  private particleSystem: ParticleSystem
  private glassEffect: GlassEffect
  private themeRenderer: ThemeRenderer
  private colors: ThemeColors
  private running = false
  private mouseX = 0
  private mouseY = 0

  constructor(colors: ThemeColors) {
    this.colors = colors
    this.particleSystem = new ParticleSystem(60)
    this.glassEffect = new GlassEffect()
    this.themeRenderer = new ThemeRenderer()
  }

  init(canvas: HTMLCanvasElement) {
    this.canvas = canvas
    this.ctx = canvas.getContext('2d')!
    this.resize()
    this.particleSystem.init(canvas.width, canvas.height)

    window.addEventListener('resize', this.handleResize)
    canvas.addEventListener('mousemove', this.handleMouseMove)
  }

  private handleResize = () => {
    if (!this.canvas || !this.ctx) return
    this.resize()
    this.particleSystem.resize(this.canvas!.width, this.canvas!.height)
  }

  private resize() {
    if (!this.canvas) return
    this.canvas.width = window.innerWidth
    this.canvas.height = window.innerHeight
  }

  private handleMouseMove = (e: MouseEvent) => {
    this.mouseX = e.clientX
    this.mouseY = e.clientY
  }

  start() {
    this.running = true
    this.loop()
  }

  stop() {
    this.running = false
    cancelAnimationFrame(this.animationId)
  }

  updateColors(colors: ThemeColors) {
    this.colors = colors
  }

  private loop = () => {
    if (!this.running || !this.ctx || !this.canvas) return
    const { ctx, canvas } = this

    ctx.clearRect(0, 0, canvas.width, canvas.height)

    this.themeRenderer.render(ctx, canvas.width, canvas.height, this.colors)

    this.glassEffect.render(ctx, canvas.width, canvas.height, this.mouseX, this.mouseY, this.colors)

    this.particleSystem.update(canvas.width, canvas.height, this.mouseX, this.mouseY)
    this.particleSystem.render(ctx, this.colors)

    this.animationId = requestAnimationFrame(this.loop)
  }

  destroy() {
    this.stop()
    window.removeEventListener('resize', this.handleResize)
    if (this.canvas) {
      this.canvas.removeEventListener('mousemove', this.handleMouseMove)
    }
  }
}
