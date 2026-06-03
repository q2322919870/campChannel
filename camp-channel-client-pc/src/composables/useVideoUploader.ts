import { ref, computed } from 'vue'
import SparkMD5 from 'spark-md5'
import { api } from '../api/client'

export type UploadStatus = 'idle' | 'hashing' | 'checking' | 'uploading' | 'success' | 'error'

export interface UseVideoUploaderOptions {
  maxOriginalSizeBytes?: number // 原始文件最大限制，默认 100MB
  uploadEndpoint?: string       // 上传接口地址，默认 /api/upload/video
  onUploaded?: (url: string) => void
}

export function useVideoUploader(options: UseVideoUploaderOptions = {}) {
  const {
    maxOriginalSizeBytes = 100 * 1024 * 1024,
    uploadEndpoint = '/api/upload/video',
    onUploaded,
  } = options

  const status = ref<UploadStatus>('idle')
  const progress = ref(0)
  const errorMsg = ref('')
  const videoUrl = ref('')
  const isDuplicated = ref(false)

  const isUploading = computed(() =>
    ['hashing', 'checking', 'uploading'].includes(status.value)
  )

  function reset() {
    status.value = 'idle'
    progress.value = 0
    errorMsg.value = ''
    videoUrl.value = ''
    isDuplicated.value = false
  }

  /**
   * 分片计算文件 Hash（防止大文件阻塞主线程）
   */
  function calculateFileHash(file: File, chunkSize = 2 * 1024 * 1024): Promise<string> {
    return new Promise((resolve, reject) => {
      const spark = new SparkMD5.ArrayBuffer()
      let currentChunk = 0
      const chunks = Math.ceil(file.size / chunkSize)

      function readNextChunk() {
        const start = currentChunk * chunkSize
        const end = Math.min(start + chunkSize, file.size)
        const reader = new FileReader()

        reader.onload = (e) => {
          const result = e.target?.result
          if (result instanceof ArrayBuffer) {
            spark.append(result)
          }
          currentChunk++
          progress.value = Math.round((currentChunk / chunks) * 50) // Hash 计算占 50% 进度

          if (currentChunk < chunks) {
            readNextChunk()
          } else {
            resolve(spark.end())
          }
        }
        reader.onerror = () => reject(new Error('文件读取失败'))
        reader.readAsArrayBuffer(file.slice(start, end))
      }

      readNextChunk()
    })
  }

  /**
   * 主流程：选择文件 → Hash计算 → 秒传校验 → 上传（后端压缩）
   */
  async function uploadVideo(file: File): Promise<string | null> {
    reset()

    // 1. 校验原始文件大小
    if (file.size > maxOriginalSizeBytes) {
      errorMsg.value = `原始文件过大（${(file.size / 1024 / 1024).toFixed(1)}MB），请选择 ${maxOriginalSizeBytes / 1024 / 1024}MB 以内的视频`
      status.value = 'error'
      return null
    }

    try {
      // 2. 计算文件 Hash
      status.value = 'hashing'
      progress.value = 0
      const fileHash = await calculateFileHash(file)

      // 3. 秒传校验：检查服务端是否已存在该文件
      status.value = 'checking'
      progress.value = 50
      try {
        const checkRes = await api.get(`/upload/video/check?hash=${fileHash}`)
        if (checkRes.data.code === 200 && checkRes.data.data?.exists) {
          // 秒传成功
          videoUrl.value = checkRes.data.data.url
          isDuplicated.value = true
          status.value = 'success'
          progress.value = 100
          onUploaded?.(videoUrl.value)
          return videoUrl.value
        }
      } catch {
        // 秒传接口不存在或失败，继续正常上传流程
      }

      // 4. 上传视频（后端负责压缩）
      status.value = 'uploading'
      progress.value = 60

      const formData = new FormData()
      formData.append('file', file)

      // 使用 XMLHttpRequest 监听上传进度
      const result = await new Promise<any>((resolve, reject) => {
        const xhr = new XMLHttpRequest()
        xhr.open('POST', uploadEndpoint)

        // 获取认证 token
        const token = localStorage.getItem('token')
        if (token) {
          xhr.setRequestHeader('Authorization', `Bearer ${token}`)
        }

        xhr.upload.onprogress = (e) => {
          if (e.lengthComputable) {
            // 上传进度占 40%（60-100）
            progress.value = 60 + Math.round((e.loaded / e.total) * 40)
          }
        }

        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            try {
              resolve(JSON.parse(xhr.responseText))
            } catch {
              reject(new Error('响应解析失败'))
            }
          } else {
            reject(new Error(`上传失败: ${xhr.status}`))
          }
        }

        xhr.onerror = () => reject(new Error('网络错误'))
        xhr.send(formData)
      })

      if (result.code === 200 && result.data?.url) {
        videoUrl.value = result.data.url
        isDuplicated.value = result.data.duplicated === 'true'
        status.value = 'success'
        progress.value = 100
        onUploaded?.(videoUrl.value)
        return videoUrl.value
      } else {
        throw new Error(result.message || '上传失败')
      }
    } catch (e: any) {
      errorMsg.value = e.message || '上传失败'
      status.value = 'error'
      return null
    }
  }

  return {
    status,
    progress,
    errorMsg,
    videoUrl,
    isDuplicated,
    isUploading,
    uploadVideo,
    reset,
  }
}
