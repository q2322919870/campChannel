// Swipe tab navigation composable
// Detects horizontal swipes to navigate between bottom tab pages
// Usage: const { onTouchStart, onTouchEnd } = useSwipeTab({ swipeThreshold?: number, avoidTop?: number })

const TAB_PAGES = [
  'pages/index/index',
  'pages/channel/channel',
  'pages/chat/list',
  'pages/notification/notification',
  'pages/profile/profile',
]

interface SwipeOptions {
  /** Minimum horizontal swipe distance to trigger (default: 50) */
  swipeThreshold?: number
  /** On index page: if touch Y < avoidTop, use a larger threshold to avoid channel swiper conflict */
  avoidTop?: number
}

export function useSwipeTab(options: SwipeOptions = {}) {
  const { swipeThreshold = 50, avoidTop = 0 } = options

  let touchStartX = 0
  let touchStartY = 0
  let touchStartTime = 0

  function onTouchStart(e: TouchEvent | UniAppTouchEvent) {
    const touch = 'touches' in e ? e.touches[0] : e
    touchStartX = touch.clientX
    touchStartY = touch.clientY
    touchStartTime = Date.now()
  }

  function onTouchEnd(e: TouchEvent | UniAppTouchEvent) {
    const touch = 'changedTouches' in e ? e.changedTouches[0] : e
    const deltaX = touch.clientX - touchStartX
    const deltaY = touch.clientY - touchStartY
    const elapsed = Date.now() - touchStartTime

    // Must be a quick swipe (under 500ms) and predominantly horizontal
    if (elapsed > 500) return
    if (Math.abs(deltaX) < Math.abs(deltaY)) return

    // Determine the effective threshold
    // On pages with avoidTop set, if touch started in the top area, use a larger threshold
    const effectiveThreshold =
      avoidTop > 0 && touchStartY < avoidTop
        ? Math.max(swipeThreshold, 120) // larger threshold to avoid channel swiper conflict
        : swipeThreshold

    if (Math.abs(deltaX) < effectiveThreshold) return

    // Find current page
    const pages = getCurrentPages()
    if (pages.length === 0) return
    const currentRoute = pages[pages.length - 1].route || ''
    const currentIdx = TAB_PAGES.findIndex((p) => p === currentRoute)
    if (currentIdx === -1) return

    const nextIdx = deltaX < 0 ? currentIdx + 1 : currentIdx - 1
    if (nextIdx >= 0 && nextIdx < TAB_PAGES.length) {
      uni.switchTab({ url: '/' + TAB_PAGES[nextIdx] })
    }
  }

  return { onTouchStart, onTouchEnd }
}

// UniApp touch event types
interface UniAppTouchEvent {
  clientX: number
  clientY: number
  touches?: Array<{ clientX: number; clientY: number }>
  changedTouches?: Array<{ clientX: number; clientY: number }>
}
