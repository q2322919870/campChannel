<template>
  <div class="login-page">
    <div class="login-container">
      <div class="brand-section">
        <div class="brand-content">
          <div class="brand-icon">
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
              <path d="M12 2L2 7l10 5 10-5-10-5z"/><path d="M2 17l10 5 10-5"/><path d="M2 12l10 5 10-5"/>
            </svg>
          </div>
          <h1 class="brand-title font-display">Camp Channel</h1>
          <p class="brand-desc">广东机电职业技术学院 · 校园频道</p>
          <div class="brand-features">
            <div class="feature-item">
              <span class="feature-dot"></span>
              <span>身份认证 · 校内专属</span>
            </div>
            <div class="feature-item">
              <span class="feature-dot"></span>
              <span>频道交流 · 兴趣聚合</span>
            </div>
            <div class="feature-item">
              <span class="feature-dot"></span>
              <span>实时聊天 · 好友互动</span>
            </div>
          </div>
        </div>
      </div>
      <div class="form-section">
        <div class="form-card">
          <h2 class="form-title">欢迎回来</h2>
          <p class="form-subtitle">使用学校邮箱登录</p>
          <form @submit.prevent="handleLogin" class="login-form">
            <div class="input-group">
              <label>学校邮箱</label>
              <div class="email-input-wrapper">
                <input v-model="studentId" type="text" class="input email-prefix" placeholder="请输入学号" required />
                <span class="email-suffix">@stu.gdmec.edu.cn</span>
              </div>
            </div>
            <div class="input-group">
              <label>密码</label>
              <input v-model="password" type="password" placeholder="输入密码" required />
            </div>
            <div class="remember-row">
              <label class="remember-label">
                <input type="checkbox" v-model="rememberMe" />
                <span>记住登录状态</span>
              </label>
            </div>
            <p v-if="error" class="error-msg">{{ error }}</p>
            <button type="submit" class="login-btn" :disabled="loading">
              {{ loading ? '登录中...' : '登录' }}
            </button>
          </form>
          <p class="register-link">
            还没有账号？<router-link to="/register">立即注册</router-link>
          </p>
          <div class="email-me">
            <a target="_blank" href="http://mail.qq.com/cgi-bin/qm_share?t=qm_mailme&email=HS8oLC8tLi8qXW5paDN6eXB4fjN4eWgzfnM" style="text-decoration:none;">
              <img src="http://rescdn.qqmail.com/zh_CN/htmledition/images/function/qm_open/ico_mailme_12.png" alt="邮我" />
              <span>联系管理员</span>
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const studentId = ref('')
const email = computed(() => studentId.value ? `${studentId.value}@stu.gdmec.edu.cn` : '')
const password = ref('')
const rememberMe = ref(true)
const loading = ref(false)
const error = ref('')

async function handleLogin() {
  if (!email.value || !password.value) return
  loading.value = true
  error.value = ''
  try {
    await authStore.login(email.value, password.value)
    if (!rememberMe.value) {
      sessionStorage.setItem('session_only', 'true')
    } else {
      sessionStorage.removeItem('session_only')
    }
    router.push('/home')
  } catch (e: any) {
    error.value = e.message || '登录失败，请检查账号密码'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  width: 100%;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.login-container {
  display: flex;
  max-width: 960px;
  width: 100%;
  min-height: 560px;
  background: var(--card-bg, var(--surface));
  backdrop-filter: blur(28px);
  -webkit-backdrop-filter: blur(28px);
  border: 1px solid var(--border-color, var(--outline-variant));
  border-radius: 24px;
  overflow: hidden;
  box-shadow: var(--card-shadow);
}
.brand-section {
  flex: 1;
  background: linear-gradient(135deg, color-mix(in srgb, var(--brand, #35bfab) 12%, transparent), color-mix(in srgb, var(--brand-secondary, #1fc9e7) 8%, transparent));
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px;
}
.brand-content { max-width: 320px; }
.brand-icon { color: var(--brand, var(--primary)); margin-bottom: 24px; }
.brand-title { font-size: 36px; font-weight: 400; margin-bottom: 8px; }
.brand-desc { color: var(--on-surface-variant); font-size: 14px; margin-bottom: 32px; }
.brand-features { display: flex; flex-direction: column; gap: 16px; }
.feature-item { display: flex; align-items: center; gap: 12px; font-size: 14px; color: var(--on-surface-variant); }
.feature-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--brand, var(--primary)); }
.form-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px;
}
.form-card { width: 100%; max-width: 340px; }
.form-title { font-size: 24px; font-weight: 600; margin-bottom: 4px; }
.form-subtitle { color: var(--on-surface-variant); font-size: 14px; margin-bottom: 32px; }
.login-form { display: flex; flex-direction: column; gap: 20px; }
.remember-row { display: flex; align-items: center; margin-top: -8px; }
.remember-label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--on-surface-variant); cursor: pointer; }
.remember-label input[type="checkbox"] { width: 16px; height: 16px; accent-color: var(--primary); cursor: pointer; }
.input-group { display: flex; flex-direction: column; gap: 8px; }
.input-group label { font-size: 13px; font-weight: 500; color: var(--on-surface-variant); }
.input-group input {
  padding: 12px 16px;
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius);
  background: rgba(255,255,255,0.03);
  color: var(--on-surface);
  font-size: 15px;
  outline: none;
  transition: border-color 0.2s;
}
.input-group input:focus { border-color: var(--primary); }
.input-group input::placeholder { color: var(--on-surface-variant); }
.email-input-wrapper {
  display: flex;
  align-items: center;
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius);
  background: rgba(255, 255, 255, 0.03);
  overflow: hidden;
  transition: all 0.2s;
}
.email-input-wrapper:focus-within {
  border-color: var(--primary);
  background: rgba(124, 159, 203, 0.08);
  box-shadow: 0 0 0 3px rgba(124, 159, 203, 0.1);
}
.email-prefix {
  border: none;
  border-radius: 0;
  background: transparent;
  flex: 1;
  min-width: 0;
  color: var(--on-surface);
}
.email-prefix:focus {
  border: none;
  box-shadow: none;
  background: transparent;
}
.email-suffix {
  padding: 12px 16px;
  color: var(--on-surface-variant);
  font-size: 14px;
  white-space: nowrap;
  user-select: none;
  background: rgba(124, 159, 203, 0.08);
  border-left: 1px solid var(--outline-variant);
}
.login-btn {
  padding: 14px;
  border: none;
  border-radius: var(--button-radius);
  background: linear-gradient(135deg, var(--brand, var(--primary)), var(--brand-secondary, var(--secondary)));
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s, transform 0.2s;
}
.login-btn:hover:not(:disabled) { transform: translateY(-1px); }
.login-btn:hover { opacity: 0.9; }
.login-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.error-msg { color: #ff6b6b; font-size: 13px; }
.register-link { text-align: center; margin-top: 24px; font-size: 14px; color: var(--on-surface-variant); }
.email-me { text-align: center; margin-top: 12px; }
.email-me a { display: inline-flex; align-items: center; gap: 6px; color: var(--on-surface-variant); font-size: 13px; transition: color 0.2s; }
.email-me a:hover { color: var(--primary); }
.email-me img { width: 14px; height: 14px; }

/* Mobile responsive */
@media (max-width: 768px) {
  .login-page { padding: 0; align-items: flex-start; }
  .login-container {
    flex-direction: column;
    min-height: auto;
    border-radius: 0;
    min-height: 100vh;
    box-shadow: none;
    border: none;
  }
  .brand-section {
    padding: 40px 24px 24px;
    flex: none;
    background: linear-gradient(180deg, rgba(124,159,203,0.12), transparent);
  }
  .brand-content { max-width: 100%; text-align: center; }
  .brand-icon { margin-bottom: 16px; }
  .brand-title { font-size: 26px; }
  .brand-desc { font-size: 13px; margin-bottom: 20px; }
  .brand-features { flex-direction: row; flex-wrap: wrap; justify-content: center; gap: 10px; }
  .feature-item { font-size: 13px; }
  .form-section { padding: 24px; flex: 1; align-items: flex-start; }
  .form-card { max-width: 100%; }
  .form-title { font-size: 22px; }
  .form-subtitle { margin-bottom: 24px; }
  .login-form { gap: 16px; }
  .input-group input { padding: 14px 16px; font-size: 16px; }
  .login-btn { padding: 16px; font-size: 17px; }
}
</style>
