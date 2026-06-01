import type { ThemeColors } from './CanvasEngine'

export class GlassEffect {
  render(
    ctx: CanvasRenderingContext2D,
    width: number,
    height: number,
    mouseX: number,
    mouseY: number,
    colors: ThemeColors
  ) {
    const gradient1 = ctx.createRadialGradient(mouseX, mouseY, 0, mouseX, mouseY, 300)
    gradient1.addColorStop(0, this.hexToRgba(colors.glowColor, 0.12))
    gradient1.addColorStop(1, 'transparent')
    ctx.fillStyle = gradient1
    ctx.fillRect(0, 0, width, height)

    const gradient2 = ctx.createRadialGradient(width * 0.8, height * 0.15, 0, width * 0.8, height * 0.15, 400)
    gradient2.addColorStop(0, this.hexToRgba(colors.primaryLight, 0.08))
    gradient2.addColorStop(1, 'transparent')
    ctx.fillStyle = gradient2
    ctx.fillRect(0, 0, width, height)

    const gradient3 = ctx.createRadialGradient(width * 0.2, height * 0.85, 0, width * 0.2, height * 0.85, 350)
    gradient3.addColorStop(0, this.hexToRgba(colors.accent, 0.08))
    gradient3.addColorStop(1, 'transparent')
    ctx.fillStyle = gradient3
    ctx.fillRect(0, 0, width, height)
  }

  private hexToRgba(hex: string, alpha: number): string {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    if (!result) return `rgba(108, 92, 231, ${alpha})`
    const r = parseInt(result[1], 16)
    const g = parseInt(result[2], 16)
    const b = parseInt(result[3], 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }
}
