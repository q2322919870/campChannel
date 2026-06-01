import type { ThemeColors } from './CanvasEngine'

export class ThemeRenderer {
  render(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    colors: ThemeColors
  ) {
    const gradient = ctx.createLinearGradient(0, 0, width, height)

    const start = this.hexToRgba(colors.gradientStart, 1)
    const end = this.hexToRgba(colors.gradientEnd, 1)

    gradient.addColorStop(0, `rgba(${start.r}, ${start.g}, ${start.b}, ${start.a})`)
    gradient.addColorStop(0.5, this.blendColors(colors.gradientStart, colors.gradientEnd, 0.5))
    gradient.addColorStop(1, `rgba(${end.r}, ${end.g}, ${end.b}, ${end.a})`)

    ctx.fillStyle = gradient
    ctx.fillRect(0, 0, width, height)
  }

  private hexToRgba(hex: string, alpha: number): { r: number; g: number; b: number; a: number } {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    if (!result) return { r: 0, g: 0, b: 0, a: 0 }
    return {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16),
      a: alpha,
    }
  }

  private blendColors(c1: string, c2: string, ratio: number): string {
    const a = this.hexToRgba(c1, 1)
    const b = this.hexToRgba(c2, 1)
    const r = Math.round(a.r + (b.r - a.r) * ratio)
    const g = Math.round(a.g + (b.g - a.g) * ratio)
    const b2 = Math.round(a.b + (b.b - a.b) * ratio)
    return `rgba(${r}, ${g}, ${b2}, 1)`
  }
}
