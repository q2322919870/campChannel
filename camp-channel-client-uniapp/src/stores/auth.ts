import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string>(uni.getStorageSync('auth_token') || '');
  const userInfo = ref<any>(uni.getStorageSync('user_info') ? JSON.parse(uni.getStorageSync('user_info')) : null);

  const setAuth = (newToken: string, user: any) => {
    token.value = newToken;
    userInfo.value = user;
    uni.setStorageSync('auth_token', newToken);
    uni.setStorageSync('user_info', JSON.stringify(user));
  };

  const clearAuth = () => {
    token.value = '';
    userInfo.value = null;
    uni.removeStorageSync('auth_token');
    uni.removeStorageSync('user_info');
  };

  const logout = () => {
    clearAuth();
  };

  return {
    token,
    userInfo,
    setAuth,
    clearAuth,
    logout
  };
});
