export interface BurstConfig {
  x: number
  y: number
  count?: number
  color?: string
  onComplete?: () => void
}

export class ParticleBurstSystem {
  private canvas: HTMLCanvasElement
  private ctx: CanvasRenderingContext2D
  private particles: Particle[] = []
  private animId = 0
  private running = false

  constructor(canvas: HTMLCanvasElement) {
    this.canvas = canvas
    this.ctx = canvas.getContext('2d')!
    this.resize()
    window.addEventListener('resize', this.resize)
  }

  private resize = () => {
    this.canvas.width = window.innerWidth
    this.canvas.height = window.innerHeight
  }

  burst(config: BurstConfig) {
    const count = config.count || 60
    const color = config.color || '#ff6b9d'
    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + (Math.random() - 0.5) * 0.3
      const speed = 4 + Math.random() * 8
      this.particles.push({
        x: config.x,
        y: config.y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed,
        life: 1,
        decay: 0.008 + Math.random() * 0.015,
        size: 3 + Math.random() * 6,
        color,
        gravity: 0.05,
      })
    }
    if (!this.running) this.start()
  }

  private start() {
    this.running = true
    const animate = () => {
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
      this.particles = this.particles.filter(p => {
        p.x += p.vx
        p.y += p.vy
        p.vy += p.gravity
        p.vx *= 0.98
        p.vy *= 0.98
        p.life -= p.decay
        if (p.life <= 0) return false
        const alpha = p.life
        this.ctx.save()
        this.ctx.globalAlpha = alpha
        this.ctx.fillStyle = p.color
        this.ctx.shadowColor = p.color
        this.ctx.shadowBlur = p.size * 2
        this.ctx.beginPath()
        this.ctx.arc(p.x, p.y, p.size * p.life, 0, Math.PI * 2)
        this.ctx.fill()
        this.ctx.restore()
        return true
      })
      if (this.particles.length > 0) {
        this.animId = requestAnimationFrame(animate)
      } else {
        this.running = false
        cancelAnimationFrame(this.animId)
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height)
      }
    }
    animate()
  }

  destroy() {
    cancelAnimationFrame(this.animId)
    window.removeEventListener('resize', this.resize)
    this.running = false
  }
}

interface Particle {
  x: number
  y: number
  vx: number
  vy: number
  life: number
  decay: number
  size: number
  color: string
  gravity: number
}
