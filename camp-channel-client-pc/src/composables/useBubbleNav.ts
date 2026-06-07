import { ref, onMounted, onUnmounted } from 'vue'

export interface BubbleLayout {
  id: string
  x: number
  y: number
  rotate: number
  scatterX: number
  scatterY: number
  scatterRotate: number
  delay: number
}

const X_JITTERS = [0, 16, -12, 20, -8, 14, -18, 10, -6, 12, -10]
const ROTATIONS = [-4, 5, -3, 6, -5, 3, -6, 4, -2, 5, -4]

export function buildBubbleLayouts(ids: string[], startY = 0, rowStep = 58): BubbleLayout[] {
  return ids.map((id, index) => {
    const scatterAngle = index * 1.35 + 0.5
    const scatterDist = 90 + (index % 4) * 35
    return {
      id,
      x: X_JITTERS[index % X_JITTERS.length],
      y: startY + index * rowStep,
      rotate: ROTATIONS[index % ROTATIONS.length],
      scatterX: Math.cos(scatterAngle) * scatterDist + (index % 2 ? 70 : -80),
      scatterY: Math.sin(scatterAngle) * scatterDist - 40,
      scatterRotate: ROTATIONS[index % ROTATIONS.length] * 3.5,
      delay: index * 60 + 80,
    }
  })
}

export function useBubbleMagnet(bubbleIds: () => string[]) {
  const mouse = ref({ x: 0, y: 0 })
  const inField = ref(false)
  const offsets = ref<Record<string, { x: number; y: number }>>({})
  const bubbleEls = ref<Record<string, HTMLElement | null>>({})

  const MAGNET_RADIUS = 130
  const STRENGTH = 0.42

  let tracking = false
  let rafId = 0

  function setBubbleEl(id: string, el: HTMLElement | null) {
    bubbleEls.value[id] = el
  }

  function tick() {
    if (!inField.value) return
    const next: Record<string, { x: number; y: number }> = {}
    for (const id of bubbleIds()) {
      const el = bubbleEls.value[id]
      if (!el) continue
      const rect = el.getBoundingClientRect()
      const cx = rect.left + rect.width / 2
      const cy = rect.top + rect.height / 2
      const dx = mouse.value.x - cx
      const dy = mouse.value.y - cy
      const dist = Math.hypot(dx, dy)
      if (dist < MAGNET_RADIUS && dist > 1) {
        const force = (1 - dist / MAGNET_RADIUS) * STRENGTH
        next[id] = { x: dx * force, y: dy * force }
      } else {
        next[id] = { x: 0, y: 0 }
      }
    }
    offsets.value = next
    rafId = requestAnimationFrame(tick)
  }

  function startTracking() {
    if (tracking) return
    tracking = true
    rafId = requestAnimationFrame(tick)
  }

  function stopTracking() {
    tracking = false
    if (rafId) cancelAnimationFrame(rafId)
    rafId = 0
    offsets.value = {}
  }

  function onMouseMove(e: MouseEvent) {
    mouse.value = { x: e.clientX, y: e.clientY }
    inField.value = true
    startTracking()
  }

  function onMouseLeave() {
    inField.value = false
    stopTracking()
  }

  onUnmounted(() => {
    stopTracking()
  })

  return { offsets, setBubbleEl, onMouseMove, onMouseLeave }
}

export function useBubbleEntrance(delayMs = 120) {
  const entered = ref(false)

  onMounted(() => {
    window.setTimeout(() => {
      entered.value = true
    }, delayMs)
  })

  return { entered }
}
