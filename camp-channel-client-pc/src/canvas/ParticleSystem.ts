import type { ThemeColors } from './CanvasEngine'

interface Particle {
  x: number
  y: number
  vx: number
  vy: number
  size: number
  alpha: number
  pulse: number
}

export class ParticleSystem {
  private particles: Particle[] = []
  private count: number

  constructor(count: number) {
    this.count = count
  }

  init(width: number, height: number) {
    this.particles = Array.from({ length: this.count }, () => this.createParticle(width, height))
  }

  resize(width: number, height: number) {
    this.particles.forEach(p => {
      p.x = Math.min(p.x, width)
      p.y = Math.min(p.y, height)
    })
  }

  private createParticle(width: number, height: number): Particle {
    return {
      x: Math.random() * width,
      y: Math.random() * height,
      vx: (Math.random() - 0.5) * 0.5,
      vy: (Math.random() - 0.5) * 0.5,
      size: Math.random() * 2 + 1,
      alpha: Math.random() * 0.5 + 0.1,
      pulse: Math.random() * Math.PI * 2,
    }
  }

  update(width: number, height: number, mouseX: number, mouseY: number) {
    this.particles.forEach(p => {
      p.x += p.vx
      p.y += p.vy
      p.pulse += 0.02

      const dx = p.x - mouseX
      const dy = p.y - mouseY
      const dist = Math.sqrt(dx * dx + dy * dy)
      if (dist < 100 && dist > 0) {
        p.x += dx / dist * 0.3
        p.y += dy / dist * 0.3
      }

      if (p.x < 0 || p.x > width) p.vx *= -1
      if (p.y < 0 || p.y > height) p.vy *= -1
    })
  }

  render(ctx: CanvasRenderingContext2D, colors: ThemeColors) {
    const time = Date.now() * 0.001

    this.particles.forEach(p => {
      const alpha = p.alpha * (0.8 + 0.2 * Math.sin(p.pulse + time))
      ctx.beginPath()
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
      ctx.fillStyle = `rgba(255, 255, 255, ${alpha})`
      ctx.fill()
    })

    for (let i = 0; i < this.particles.length; i++) {
      for (let j = i + 1; j < this.particles.length; j++) {
        const dx = this.particles[i].x - this.particles[j].x
        const dy = this.particles[i].y - this.particles[j].y
        const dist = Math.sqrt(dx * dx + dy * dy)

        if (dist < 150) {
          const alpha = (1 - dist / 150) * 0.15
          ctx.beginPath()
          ctx.moveTo(this.particles[i].x, this.particles[i].y)
          ctx.lineTo(this.particles[j].x, this.particles[j].y)
          ctx.strokeStyle = `rgba(255, 255, 255, ${alpha})`
          ctx.lineWidth = 0.5
          ctx.stroke()
        }
      }
    }
  }
}
