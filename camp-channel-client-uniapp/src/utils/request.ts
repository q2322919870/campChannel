// 广东机电校园频道 UniApp 网络请求封装
// Try storage first, fallback to default
const storedUrl = uni.getStorageSync('api_base_url')
export const BASE_URL = storedUrl || 'http://10.50.30.104:8080/api'

interface RequestOptions {
  url: string;
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  data?: any;
  header?: any;
}

/**
 * Process image URL - convert relative path to absolute URL
 */
export function processImageUrl(url: string): string {
  if (!url) return ''
  // If already absolute URL, return as is
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url
  }
  // Convert relative path to absolute, keeping API context-path
  // e.g., /uploads/avatars/xxx.jpg → http://localhost:8080/api/uploads/avatars/xxx.jpg
  return `${BASE_URL}${url}`
}

/**
 * 统一网络请求核心方法
 */
export const request = <T = any>(options: string | RequestOptions): Promise<T> => {
  // Support both (url) and ({url, method, data}) signatures
  if (typeof options === 'string') {
    options = { url: options }
  }
  return new Promise((resolve, reject) => {
    // 1. 从缓存获取 Token
    const token = uni.getStorageSync('auth_token');
    
    // 2. 合并 headers
    const header = {
      'Content-Type': 'application/json',
      ...options.header
    };
    if (token) {
      header['Authorization'] = token;
    }

    // 3. 执行 uni.request 调用
    uni.request({
      url: `${BASE_URL}${options.url}`,
      method: options.method || 'GET',
      data: options.data,
      header: header,
      success: (res) => {
        const responseData = res.data as any;

        // 4. 判断 HTTP 状态码或业务下线状态
        if (res.statusCode === 401 || (responseData && responseData.code === 1009)) {
          // 触发强制下线逻辑
          handleForceLogout(responseData?.message || '登录状态已过期，请重新登录');
          reject(new Error(responseData?.message || 'Unauthorized'));
          return;
        }

        if (res.statusCode === 200) {
          resolve(responseData as T);
        } else {
          uni.showToast({
            title: responseData?.message || '系统繁忙，请稍候再试',
            icon: 'none'
          });
          reject(new Error(responseData?.message || 'HTTP Error'));
        }
      },
      fail: (err) => {
        uni.showToast({
          title: '网络连接失败，请检查后端服务是否启动',
          icon: 'none'
        });
        reject(err);
      }
    });
  });
};

/**
 * 处理单设备互踢及凭证过期逻辑
 */
function handleForceLogout(reason: string) {
  // 1. 清除本地缓存凭证
  uni.removeStorageSync('auth_token');
  uni.removeStorageSync('user_info');

  // 2. 弹窗醒目警告
  uni.showModal({
    title: '下线通知',
    content: reason,
    showCancel: false,
    confirmText: '重新登录',
    success: (res) => {
      if (res.confirm) {
        // 跳转登录页（如果使用的是 TabBar 页面，需用 uni.switchTab，此处假定为普通登录页面）
        uni.reLaunch({
          url: '/pages/login/login'
        });
      }
    }
  });
}

export default request
