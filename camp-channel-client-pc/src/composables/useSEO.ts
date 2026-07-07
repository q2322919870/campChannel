import { onMounted, onUnmounted } from 'vue'

/**
 * SEO 优化 composable
 * 动态管理页面标题和 meta 描述
 */
const DEFAULT_TITLE = 'Camp Channel 校园频道'
const DEFAULT_DESCRIPTION = 'Camp Channel 校园频道系统 - 让校园生活更精彩'

export function useSEO() {
  let originalTitle: string
  let originalDescription: string

  const setTitle = (title: string) => {
    document.title = title ? `${title} - Camp Channel` : DEFAULT_TITLE
  }

  const setMetaDescription = (description: string) => {
    let meta = document.querySelector('meta[name="description"]') as HTMLMetaElement | null
    if (!meta) {
      meta = document.createElement('meta')
      meta.setAttribute('name', 'description')
      document.head.appendChild(meta)
    }
    meta.setAttribute('content', description || DEFAULT_DESCRIPTION)
  }

  const setMetaKeywords = (keywords: string) => {
    let meta = document.querySelector('meta[name="keywords"]') as HTMLMetaElement | null
    if (!meta) {
      meta = document.createElement('meta')
      meta.setAttribute('name', 'keywords')
      document.head.appendChild(meta)
    }
    meta.setAttribute('content', keywords)
  }

  const setOGTags = (opts: { title?: string; description?: string; image?: string; url?: string }) => {
    const setOG = (property: string, content: string) => {
      let meta = document.querySelector(`meta[property="${property}"]`) as HTMLMetaElement | null
      if (!meta) {
        meta = document.createElement('meta')
        meta.setAttribute('property', property)
        document.head.appendChild(meta)
      }
      meta.setAttribute('content', content)
    }
    if (opts.title) setOG('og:title', opts.title)
    if (opts.description) setOG('og:description', opts.description)
    if (opts.image) setOG('og:image', opts.image)
    if (opts.url) setOG('og:url', opts.url)
  }

  const initSEO = (title?: string, description?: string) => {
    originalTitle = document.title
    originalDescription = (document.querySelector('meta[name="description"]') as HTMLMetaElement)?.content || DEFAULT_DESCRIPTION
    if (title) setTitle(title)
    if (description) setMetaDescription(description)
  }

  const restoreSEO = () => {
    if (originalTitle) document.title = originalTitle
    if (originalDescription) setMetaDescription(originalDescription)
  }

  return {
    setTitle,
    setMetaDescription,
    setMetaKeywords,
    setOGTags,
    initSEO,
    restoreSEO,
  }
}
