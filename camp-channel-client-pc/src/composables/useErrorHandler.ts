/**
 * 统一错误处理 composable
 * 提供友好的错误提示和分类处理
 */

type ToastFn = (message: string, type?: 'success' | 'error' | 'warning' | 'info') => void

let _toastFn: ToastFn | null = null

export function setToastHandler(fn: ToastFn) {
  _toastFn = fn
}

function showToast(message: string, type: 'success' | 'error' | 'warning' | 'info' = 'error') {
  if (_toastFn) {
    _toastFn(message, type)
  } else {
    console.warn(`[${type}] ${message}`)
  }
}

export function useErrorHandler() {
  const handleError = (error: any, customMessage?: string) => {
    // 优先使用自定义消息
    if (customMessage) {
      showToast(customMessage, 'error')
      return
    }

    const status = error?.response?.status
    const message = error?.response?.data?.message

    switch (status) {
      case 400:
        showToast(message || '请求参数错误', 'error')
        break
      case 401:
        showToast('登录已过期，请重新登录', 'warning')
        break
      case 403:
        showToast('无权访问此资源', 'error')
        break
      case 404:
        showToast('请求的资源不存在', 'error')
        break
      case 429:
        showToast('请求过于频繁，请稍后再试', 'warning')
        break
      case 500:
        showToast('服务器内部错误，请稍后重试', 'error')
        break
      case 502:
      case 503:
      case 504:
        showToast('服务暂时不可用，请稍后重试', 'error')
        break
      default:
        if (error?.code === 'ERR_NETWORK') {
          showToast('网络连接失败，请检查网络', 'error')
        } else if (error?.message) {
          showToast(error.message, 'error')
        } else {
          showToast('未知错误，请稍后重试', 'error')
        }
    }
  }

  const handleSuccess = (message: string) => {
    showToast(message, 'success')
  }

  const handleWarning = (message: string) => {
    showToast(message, 'warning')
  }

  return { handleError, handleSuccess, handleWarning }
}
