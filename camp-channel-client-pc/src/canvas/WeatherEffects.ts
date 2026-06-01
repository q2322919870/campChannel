/**
 * Weather Effects - Canvas2D rain/snow/neon renderers for PC client.
 * Environment-responsive dynamic profile overlay.
 */

export type TimePeriod = 'morning' | 'afternoon' | 'evening' | 'night'

export function getCurrentTimePeriod(): TimePeriod {
  const hour = new Date().getHours()
  if (hour >= 5 && hour < 12) return 'morning'
  if (hour >= 12 && hour < 17) return 'afternoon'
  if (hour >= 17 && hour < 20) return 'evening'
  return 'night'
}

export function getTimePeriodTint(period: TimePeriod): string {
  switch (period) {
    case 'morning': return 'rgba(255, 215, 0, 0.06)'
    case 'afternoon': return 'transparent'
    case 'evening': return 'rgba(255, 107, 53, 0.08)'
    case 'night': return 'rgba(74, 0, 224, 0.1)'
  }
}

export class WeatherEffectsRenderer {
  private canvas: HTMLCanvasElement
  private ctx: CanvasRenderingContext2D
  private animId = 0
  private running = false
  private startTime = 0
  private period: TimePeriod

  // Pre-generated random values for particles
  private rainDrops: { x: number; speed: number; len: number; alpha: number }[] = []
  private snowFlakes: { x: number; speed: number; r: number; alpha: number; drift: number }[] = []
  private stars: { x: number; y: number; r: number; twinkleOffset: number }[] = []

  constructor(canvas: HTMLCanvasElement, period: TimePeriod) {
    this.canvas = canvas
    this.ctx = canvas.getContext('2d')!
    this.period = period
    this.initParticles()
  }

  private initParticles() {
    const w = this.canvas.width
    const h = this.canvas.height

    // Rain drops
    for (let i = 0; i < 30; i++) {
      this.rainDrops.push({
        x: Math.random() * w,
        speed: 80 + Math.random() * 120,
        len: 8 + Math.random() * 16,
        alpha: 0.15 + Math.random() * 0.2,
      })
    }

    // Snow flakes
    for (let i = 0; i < 25; i++) {
      this.snowFlakes.push({
        x: Math.random() * w,
        speed: 20 + Math.random() * 30,
        r: 1.5 + Math.random() * 3,
        alpha: 0.2 + Math.random() * 0.3,
        drift: Math.random() * Math.PI * 2,
      })
    }

    // Stars
    for (let i = 0; i < 15; i++) {
      this.stars.push({
        x: Math.random() * w,
        y: Math.random() * h * 0.3,
        r: 0.5 + Math.random() * 1.5,
        twinkleOffset: Math.random() * Math.PI * 2,
      })
    }
  }

  resize(w: number, h: number) {
    this.canvas.width = w
    this.canvas.height = h
    this.initParticles()
  }

  start() {
    if (this.running) return
    this.running = true
    this.startTime = performance.now()
    const animate = () => {
      if (!this.running) return
      const t = (performance.now() - this.startTime) / 1000
      this.render(t)
      this.animId = requestAnimationFrame(animate)
    }
    animate()
  }

  stop() {
    this.running = false
    cancelAnimationFrame(this.animId)
  }

  private render(t: number) {
    const { ctx, canvas } = this
    const w = canvas.width
    const h = canvas.height
    ctx.clearRect(0, 0, w, h)

    // Time period tint
    const tint = getTimePeriodTint(this.period)
    if (tint !== 'transparent') {
      ctx.fillStyle = tint
      ctx.fillRect(0, 0, w, h)
    }

    switch (this.period) {
      case 'night':
        this.renderStars(t)
        this.renderNeonGlow(t)
        this.renderRain(t, 'rgba(108, 99, 255,')
        break
      case 'evening':
        this.renderSunsetGradient()
        break
      case 'morning':
        this.renderWarmGlow(t)
        if (this.isWinter()) {
          this.renderSnow(t)
        }
        break
      case 'afternoon':
        // Clear, no effects
        break
    }
  }

  private renderRain(t: number, colorBase: string) {
    const { ctx, canvas } = this
    const h = canvas.height

    ctx.strokeStyle = colorBase + '0.2)'
    ctx.lineWidth = 1.5
    ctx.lineCap = 'round'

    for (const drop of this.rainDrops) {
      const y = ((t * drop.speed) % (h + drop.len)) - drop.len
      ctx.globalAlpha = drop.alpha
      ctx.beginPath()
      ctx.moveTo(drop.x, y)
      ctx.lineTo(drop.x - 1, y + drop.len)
      ctx.stroke()
    }
    ctx.globalAlpha = 1
  }

  private renderSnow(t: number) {
    const { ctx, canvas } = this
    const w = canvas.width
    const h = canvas.height

    for (const flake of this.snowFlakes) {
      const y = ((t * flake.speed) % (h + flake.r * 2)) - flake.r
      const x = flake.x + Math.sin(t * 0.8 + flake.drift) * 20
      ctx.globalAlpha = flake.alpha
      ctx.fillStyle = '#fff'
      ctx.beginPath()
      ctx.arc(x % w, y, flake.r, 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.globalAlpha = 1
  }

  private renderStars(t: number) {
    const { ctx } = this

    for (const star of this.stars) {
      const twinkle = Math.sin(t * 2 + star.twinkleOffset) * 0.3 + 0.4
      ctx.globalAlpha = twinkle
      ctx.fillStyle = '#fff'
      ctx.beginPath()
      ctx.arc(star.x, star.y, star.r, 0, Math.PI * 2)
      ctx.fill()
    }
    ctx.globalAlpha = 1
  }

  private renderNeonGlow(t: number) {
    const { ctx, canvas } = this
    const w = canvas.width
    const h = canvas.height
    const pulse = Math.sin(t * 1.2) * 0.15 + 0.25

    // Top edge
    const topGrad = ctx.createLinearGradient(0, 0, w, 0)
    topGrad.addColorStop(0, `rgba(108, 99, 255, ${pulse})`)
    topGrad.addColorStop(1, `rgba(255, 101, 132, ${pulse})`)
    ctx.fillStyle = topGrad
    ctx.fillRect(0, 0, w, 2)

    // Side glows
    ctx.shadowBlur = 12
    ctx.shadowColor = `rgba(108, 99, 255, ${pulse * 0.5})`
    ctx.fillStyle = `rgba(108, 99, 255, ${pulse * 0.3})`
    ctx.fillRect(0, 0, 2, h)

    ctx.shadowColor = `rgba(255, 101, 132, ${pulse * 0.5})`
    ctx.fillStyle = `rgba(255, 101, 132, ${pulse * 0.3})`
    ctx.fillRect(w - 2, 0, 2, h)

    ctx.shadowBlur = 0
  }

  private renderSunsetGradient() {
    const { ctx, canvas } = this
    const w = canvas.width
    const h = canvas.height

    const grad = ctx.createLinearGradient(0, 0, 0, h)
    grad.addColorStop(0, 'rgba(255, 107, 53, 0.06)')
    grad.addColorStop(0.5, 'rgba(255, 165, 0, 0.04)')
    grad.addColorStop(1, 'transparent')
    ctx.fillStyle = grad
    ctx.fillRect(0, 0, w, h)
  }

  private renderWarmGlow(t: number) {
    const { ctx, canvas } = this
    const w = canvas.width
    const h = canvas.height
    const pulse = Math.sin(t * 0.5) * 0.02 + 0.04

    const grad = ctx.createRadialGradient(w * 0.7, h * 0.2, 0, w * 0.7, h * 0.2, w * 0.6)
    grad.addColorStop(0, `rgba(255, 215, 0, ${pulse})`)
    grad.addColorStop(1, 'transparent')
    ctx.fillStyle = grad
    ctx.fillRect(0, 0, w, h)
  }

  private isWinter(): boolean {
    const month = new Date().getMonth() + 1
    return month >= 12 || month <= 2
  }
}
