﻿﻿﻿﻿﻿<template>
  <div class="register-page">
    <div class="register-bg"></div>
    <div class="register-container">
      <div class="register-header">
        <div class="logo-icon">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/>
          </svg>
        </div>
        <h1 class="register-title">创建你的账号</h1>
        <p class="register-subtitle">使用学校邮箱加入Camp Channel</p>
      </div>

      <div class="register-form-wrapper">
        <form @submit.prevent="handleRegister" class="register-form">
          <div class="form-grid">
              <div class="form-field">
              <div class="label-row">
                <label class="field-label">学号</label>
                <a
                  class="m3-link"
                  href="https://wxzx.gdmec.edu.cn/xsfw/xyyxsysm.htm"
                  target="_blank"
                  rel="noopener noreferrer"
                >没有学校邮箱？</a>
              </div>
              <div class="email-input-group">
                <input v-model="studentId" type="text" class="field-input" placeholder="输入学号" required />
                <span class="email-suffix">@stu.gdmec.edu.cn</span>
              </div>
            </div>

            <div class="form-field">
              <label class="field-label">用户名</label>
              <input v-model="username" type="text" class="field-input" placeholder="2-20位字符" required />
            </div>

            <div class="form-field">
              <label class="field-label">密码</label>
              <input v-model="password" type="password" class="field-input" placeholder="8-20位，含字母+数字" required />
            </div>

            <div class="form-field">
              <label class="field-label">验证码</label>
              <div class="code-row">
                <input v-model="code" type="text" class="field-input code-input" placeholder="6位验证码" maxlength="6" required />
                <button type="button" class="code-btn" :disabled="codeLoading || codeTimer > 0" @click="sendCode">
                  {{ codeTimer > 0 ? codeTimer + 's' : (codeLoading ? '发送中...' : '获取验证码') }}
                </button>
              </div>
            </div>

            <div class="form-field">
              <label class="field-label">真实姓名</label>
              <input v-model="realName" type="text" class="field-input" placeholder="请输入真实姓名" required />
            </div>
          </div>

          <div class="checkbox-field">
            <label class="checkbox-label">
              <input type="checkbox" v-model="agreeProtocol" />
              <span class="checkbox-text">我已阅读并同意 <a href="#" @click.prevent>《用户协议》</a>和<a href="#" @click.prevent>《隐私政策》</a></span>
            </label>
          </div>

          <p v-if="error" class="error-msg">{{ error }}</p>

          <button type="submit" class="submit-btn" :disabled="loading || !agreeProtocol">
            <span v-if="loading" class="loading-spinner"></span>
            {{ loading ? '注册中...' : '注册' }}
          </button>
        </form>

        <div class="login-link">
          已有账号？<router-link to="/login">立即登录</router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { api } from '../api/client'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const studentId = ref('')
const email = computed(() => {
  const id = studentId.value.trim()
  if (!id) return ''
  // Strip suffix if user typed full email to prevent double suffix
  if (id.endsWith('@stu.gdmec.edu.cn')) return id
  return `${id}@stu.gdmec.edu.cn`
})
const username = ref('')
const password = ref('')
const code = ref('')
const realName = ref('')
const agreeProtocol = ref(false)
const loading = ref(false)
const codeLoading = ref(false)
const codeTimer = ref(0)
const error = ref('')
let timerInterval: ReturnType<typeof setInterval> | null = null

async function sendCode() {
  if (!studentId.value) {
    error.value = '请输入学号'
    return
  }
  codeLoading.value = true
  error.value = ''
  try {
    await api.post('/auth/send-code', { email: email.value })
    codeTimer.value = 60
    timerInterval = setInterval(() => {
      codeTimer.value--
      if (codeTimer.value <= 0 && timerInterval) {
        clearInterval(timerInterval)
        timerInterval = null
      }
    }, 1000)
  } catch (e: any) {
    error.value = e.response?.data?.message || '验证码发送失败'
  } finally {
    codeLoading.value = false
  }
}

onUnmounted(() => {
  if (timerInterval) clearInterval(timerInterval)
})

async function handleRegister() {
  if (!studentId.value || !username.value || !password.value) return
  loading.value = true
  error.value = ''
  try {
    await authStore.register(email.value, username.value, password.value, code.value, realName.value)
    alert('注册成功！请登录')
    router.push('/login')
  } catch (e: any) {
    error.value = e.message || '注册失败'
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.register-page {
  width: 100%;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
  background: var(--background);
  position: relative;
  overflow: hidden;
}

.register-bg {
  position: absolute;
  inset: 0;
  background: 
    radial-gradient(ellipse at 20% 50%, var(--primary) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, var(--secondary) 0%, transparent 50%),
    radial-gradient(ellipse at 40% 80%, var(--on-primary-container) 0%, transparent 50%);
  opacity: 0.08;
  pointer-events: none;
}

.register-container {
  width: 100%;
  max-width: 480px;
  background: var(--surface);
  backdrop-filter: blur(24px);
  border: 1px solid var(--outline-variant);
  border-radius: var(--card-radius);
  padding: 40px 32px;
  box-shadow: var(--card-shadow);
  position: relative;
  z-index: 1;
  animation: slideUp 0.4s ease-out;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(20px); }
  to { opacity: 1; transform: translateY(0); }
}

.register-header {
  text-align: center;
  margin-bottom: 32px;
}

.logo-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto 16px;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  border-radius: var(--radius);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}

.register-title {
  font-size: 28px;
  font-weight: 700;
  margin-bottom: 8px;
  color: var(--on-surface);
}

.register-subtitle {
  font-size: 14px;
  color: var(--on-surface-variant);
}

.register-form-wrapper {
  width: 100%;
}

.register-form {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.form-grid {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.form-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.field-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--on-surface);
}

.field-input {
  padding: 12px 16px;
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius);
  background: rgba(255, 255, 255, 0.03);
  color: var(--on-surface);
  font-size: 15px;
  outline: none;
  transition: all 0.2s;
}

.field-input:hover {
  border-color: var(--primary);
}

.field-input:focus {
  border-color: var(--secondary);
  background: rgba(255, 255, 255, 0.05);
  box-shadow: 0 0 0 3px rgba(3, 218, 198, 0.1);
}

.field-input::placeholder {
  color: var(--on-surface-variant);
}

.email-input-group {
  display: flex;
  align-items: center;
  border: 1px solid var(--outline-variant);
  border-radius: var(--radius);
  background: rgba(255, 255, 255, 0.03);
  overflow: hidden;
  transition: all 0.2s;
}

.email-input-group:hover {
  border-color: var(--primary);
}

.email-input-group:focus-within {
  border-color: var(--secondary);
  background: rgba(255, 255, 255, 0.05);
  box-shadow: 0 0 0 3px rgba(3, 218, 198, 0.1);
}

.email-input-group .field-input {
  border: none;
  background: transparent;
  flex: 1;
}

.email-input-group .field-input:focus {
  box-shadow: none;
}

.email-suffix {
  padding: 12px 16px;
  color: var(--on-surface-variant);
  font-size: 14px;
  white-space: nowrap;
  user-select: none;
  background: rgba(255, 255, 255, 0.05);
  border-left: 1px solid var(--outline-variant);
}

.code-row {
  display: flex;
  gap: 8px;
}

.code-row .field-input {
  flex: 1;
}

.code-btn {
  flex-shrink: 0;
  padding: 12px 16px;
  border: 1px solid var(--primary);
  border-radius: var(--button-radius);
  background: transparent;
  color: var(--primary);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.code-btn:hover:not(:disabled) {
  background: var(--primary);
  color: #fff;
}

.code-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.checkbox-field {
  margin-top: 4px;
}

.checkbox-label {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  font-size: 13px;
  color: var(--on-surface-variant);
  cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
  accent-color: var(--secondary);
  width: 16px;
  height: 16px;
  cursor: pointer;
  margin-top: 2px;
}

.checkbox-text a {
  color: var(--primary);
  text-decoration: none;
}

.checkbox-text a:hover {
  color: var(--secondary);
  text-decoration: underline;
}

.error-msg {
  color: var(--secondary);
  font-size: 13px;
  text-align: center;
}

.submit-btn {
  padding: 14px;
  border: none;
  border-radius: var(--button-radius);
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.submit-btn:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(98, 0, 238, 0.3);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.loading-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.login-link {
  text-align: center;
  margin-top: 24px;
  font-size: 14px;
  color: var(--on-surface-variant);
}

.login-link a {
  color: var(--primary);
  text-decoration: none;
  font-weight: 500;
}

.login-link a:hover {
  color: var(--secondary);
  text-decoration: underline;
}

.label-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.m3-link {
  font-size: 13px;
  font-weight: 500;
  color: var(--primary);
  text-decoration: none;
  padding: 0 2px;
  border-radius: 4px;
  transition: all 0.2s cubic-bezier(0.2, 0, 0, 1);
  position: relative;
  letter-spacing: 0.1px;
}

.m3-link::after {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0px;
  height: 1px;
  background: currentColor;
  transform: scaleX(0);
  transform-origin: left;
  transition: transform 0.2s cubic-bezier(0.2, 0, 0, 1);
}

.m3-link:hover {
  color: var(--secondary);
}

.m3-link:hover::after {
  transform: scaleX(1);
}

.m3-link:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

@media (max-width: 768px) {
  .register-page {
    padding: 16px;
  }

  .register-container {
    padding: 32px 24px;
    max-width: 100%;
  }

  .register-title {
    font-size: 24px;
  }
}
</style>
