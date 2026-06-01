<template>
  <div class="settings-page">
    <h1 class="page-title">设置</h1>

    <div class="settings-section">
      <h2 class="section-title">主题</h2>
      <div class="theme-grid">
        <div
          v-for="(theme, index) in themeStore.themeList"
          :key="index"
          class="theme-card"
          :class="{ active: themeStore.themeIndex === index }"
          @click="themeStore.setTheme(index)"
        >
          <div class="theme-preview" :style="{ background: `linear-gradient(135deg, ${theme.primary}, ${theme.accent})` }"></div>
          <div class="theme-info">
            <span class="theme-name">{{ theme.name }}</span>
            <span v-if="themeStore.themeIndex === index" class="theme-check">✓</span>
          </div>
        </div>
      </div>
    </div>

    <div class="settings-section">
      <h2 class="section-title">账号</h2>
      <div class="settings-card">
        <div class="setting-item" style="cursor:pointer;" @click="triggerUpload">
          <div class="setting-label">
            <span class="setting-name">头像</span>
            <span class="setting-desc">点击更换头像</span>
          </div>
          <div class="setting-avatar" @click.stop="previewAvatar">
            <img v-if="currentAvatar" :src="currentAvatar" />
            <span v-else>{{ (authStore.user?.username || '?').charAt(0) }}</span>
          </div>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
          <input ref="fileInput" type="file" accept="image/png,image/jpeg,image/gif,image/webp,image/svg+xml" hidden @change="uploadAvatar" />
        </div>
        <div class="setting-item">
          <div class="setting-label">
            <span class="setting-name">邮箱</span>
            <span class="setting-desc">{{ authStore.user?.email || '未设置' }}</span>
          </div>
        </div>
        <div class="setting-item">
          <div class="setting-label">
            <span class="setting-name">邮件提醒</span>
            <span class="setting-desc">{{ emailNotify ? '已开启' : '已关闭' }}</span>
          </div>
          <label class="toggle-switch">
            <input type="checkbox" :checked="emailNotify" @change="toggleEmailNotify" />
            <span class="toggle-slider"></span>
          </label>
        </div>
        <div class="setting-item" style="cursor:pointer;" @click="showUsernameInput = !showUsernameInput">
          <div class="setting-label">
            <span class="setting-name">用户名</span>
            <span class="setting-desc">{{ authStore.user?.username || '未设置' }}</span>
          </div>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
        </div>
        <div v-if="showUsernameInput" class="password-form">
          <input v-model="newUsername" :placeholder="authStore.user?.username || '新用户名'" />
          <p v-if="usernameError" class="pw-error">{{ usernameError }}</p>
          <button class="pw-btn" @click="updateUsername">保存用户名</button>
        </div>
        <div class="setting-item">
          <div class="setting-label">
            <span class="setting-name">角色</span>
            <span class="setting-desc">{{ authStore.user?.role === 'sys_admin' ? '系统管理员' : '学生用户' }}</span>
          </div>
        </div>
        <div class="setting-item" style="cursor:pointer;" @click="showPasswordForm = !showPasswordForm">
          <div class="setting-label">
            <span class="setting-name">密码</span>
            <span class="setting-desc">点击修改密码</span>
          </div>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
        </div>
        <div v-if="showPasswordForm" class="password-form">
          <input v-model="oldPassword" type="password" placeholder="原密码" />
          <input v-model="newPassword" type="password" placeholder="新密码" />
          <input v-model="confirmPassword" type="password" placeholder="确认新密码" />
          <p v-if="pwError" class="pw-error">{{ pwError }}</p>
          <button class="pw-btn" @click="changePassword">修改密码</button>
        </div>
      </div>
    </div>

    <div class="settings-section">
      <h2 class="section-title">设备</h2>
      <div class="settings-card">
        <div class="setting-item" style="cursor: pointer;" @click="$router.push('/device-management')">
          <div class="setting-label">
            <span class="setting-name">登录设备</span>
            <span class="setting-desc">查看和管理登录设备</span>
          </div>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
        </div>
      </div>
    </div>

    <div class="settings-section">
      <h2 class="section-title">关于</h2>
      <div class="settings-card">
        <div class="setting-item">
          <span class="setting-name">版本</span>
          <span class="setting-desc">Camp Channel V1.0</span>
        </div>
        <div class="setting-item">
          <span class="setting-name">学校</span>
          <span class="setting-desc">广东机电职业技术学院</span>
        </div>
      </div>
    </div>

    <div class="settings-section">
      <button class="logout-btn-full" @click="handleLogout">退出登录</button>
    </div>

    <teleport to="body">
      <div v-if="showPreview" class="avatar-preview-overlay" @click.self="showPreview = false">
        <div class="avatar-preview-card" @click.stop>
          <img :src="currentAvatar" class="avatar-preview-img" />
          <div class="avatar-preview-actions">
            <button class="preview-btn" @click="downloadAvatar">下载图片</button>
          </div>
          <button class="close-preview" @click="showPreview = false">关闭</button>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useThemeStore } from '../stores/theme'
import { useAuthStore } from '../stores/auth'
import { api } from '../api/client'

const router = useRouter()
const themeStore = useThemeStore()
const authStore = useAuthStore()
const showPasswordForm = ref(false)
const showPreview = ref(false)
const fileInput = ref<HTMLInputElement>()

const currentAvatar = computed(() => authStore.user?.avatar || '')

function previewAvatar() {
  if (currentAvatar.value) showPreview.value = true
}

function downloadAvatar() {
  if (currentAvatar.value) {
    const a = document.createElement('a')
    a.href = currentAvatar.value
    a.download = 'avatar.jpg'
    a.click()
  }
}

function triggerUpload() { fileInput.value?.click() }

async function uploadAvatar(e: Event) {
  const input = e.target as HTMLInputElement
  if (!input.files?.length) return
  const file = input.files[0]
  if (file.size > 10 * 1024 * 1024) {
    alert('图片不能超过10MB')
    input.value = ''
    return
  }
  const formData = new FormData()
  formData.append('file', file)
  try {
    const res = await api.post('/users/avatar', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    if (res.data.code === 200 && res.data.data?.url) {
      if (authStore.user) authStore.user.avatar = res.data.data.url
      alert('头像更新成功')
    } else {
      alert(res.data.message || '上传失败')
    }
  } catch (e: any) {
    alert(e.response?.data?.message || e.message || '上传失败')
  }
  input.value = ''
}

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

const emailNotify = computed(() => authStore.user?.emailNotify !== 0)

async function toggleEmailNotify(e: Event) {
  const checked = (e.target as HTMLInputElement).checked
  try {
    await api.put('/users/me', { emailNotify: checked ? 1 : 0 })
    if (authStore.user) authStore.user.emailNotify = checked ? 1 : 0
  } catch {
    alert('设置失败')
  }
}
const showUsernameInput = ref(false)
const newUsername = ref('')
const usernameError = ref('')

async function updateUsername() {
  usernameError.value = ''
  if (!newUsername.value.trim()) { usernameError.value = '用户名不能为空'; return }
  if (newUsername.value.trim().length < 2) { usernameError.value = '用户名至少2个字符'; return }
  try {
    const res = await api.put('/users/me', { username: newUsername.value.trim() })
    if (res.data.code === 200 && authStore.user) {
      authStore.user.username = newUsername.value.trim()
      showUsernameInput.value = false
      newUsername.value = ''
    } else {
      usernameError.value = res.data.message || '修改失败'
    }
  } catch (e: any) {
    usernameError.value = e.response?.data?.message || '修改失败'
  }
}

const oldPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const pwError = ref('')

async function changePassword() {
  pwError.value = ''
  if (!oldPassword.value || !newPassword.value || !confirmPassword.value) {
    pwError.value = '请填写所有字段'
    return
  }
  if (newPassword.value !== confirmPassword.value) {
    pwError.value = '两次密码不一致'
    return
  }
  if (newPassword.value.length < 8) {
    pwError.value = '密码至少8位'
    return
  }
  try {
    const res = await api.post('/users/change-password', { oldPassword: oldPassword.value, newPassword: newPassword.value })
    if (res.data.code === 200) {
      oldPassword.value = ''
      newPassword.value = ''
      confirmPassword.value = ''
      showPasswordForm.value = false
      window.alert('密码修改成功，请重新登录')
    } else {
      pwError.value = res.data.message || '修改失败'
    }
  } catch (e: any) {
    pwError.value = e.response?.data?.message || '修改失败'
  }
}
</script>

<style scoped>
.settings-page { max-width: 720px; margin: 0 auto; }
.page-title { font-size: 28px; font-weight: 700; margin-bottom: 32px; }
.settings-section { margin-bottom: 32px; }
.section-title { font-size: 16px; font-weight: 600; margin-bottom: 16px; color: var(--text-secondary); }
.theme-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.theme-card {
  padding: 12px; background: var(--card); border: 1px solid var(--border); border-radius: 14px;
  cursor: pointer; transition: all 0.2s;
}
.theme-card:hover { border-color: var(--primary); }
.theme-card.active { border-color: var(--primary); background: rgba(124,159,203,0.08); }
.theme-preview { width: 100%; height: 60px; border-radius: 8px; margin-bottom: 8px; }
.theme-info { display: flex; justify-content: space-between; align-items: center; }
.theme-name { font-size: 12px; font-weight: 500; }
.theme-check { color: var(--primary); font-weight: 700; font-size: 14px; }

.settings-card { background: var(--card); border: 1px solid var(--border); border-radius: 16px; overflow: hidden; }
.setting-item { display: flex; justify-content: space-between; align-items: center; padding: 16px 20px; border-bottom: 1px solid var(--border); }
.setting-item:last-child { border-bottom: none; }
.setting-label { display: flex; flex-direction: column; gap: 2px; }
.setting-name { font-size: 14px; font-weight: 500; }
.setting-desc { font-size: 13px; color: var(--text-secondary); }
.password-form { display: flex; flex-direction: column; gap: 8px; padding: 16px; border-top: 1px solid var(--border); }
.password-form input { padding: 10px 14px; border: 1px solid var(--border); border-radius: 10px; background: rgba(255,255,255,0.03); color: var(--text); font-size: 13px; outline: none; }
.password-form input:focus { border-color: var(--primary); }
.pw-btn { padding: 10px; border: none; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--accent)); color: #fff; font-size: 14px; font-weight: 600; cursor: pointer; }
.pw-error { color: #ff6b6b; font-size: 12px; }
.logout-btn-full { width: 100%; padding: 14px; border: 1px solid rgba(255,107,107,0.3); border-radius: 14px; background: rgba(255,107,107,0.05); color: #ff6b6b; font-size: 15px; font-weight: 600; cursor: pointer; }
.logout-btn-full:hover { background: rgba(255,107,107,0.1); }

/* Toggle Switch */
.toggle-switch { position: relative; display: inline-block; width: 44px; height: 24px; cursor: pointer; }
.toggle-switch input { opacity: 0; width: 0; height: 0; }
.toggle-slider { position: absolute; inset: 0; background: var(--border); border-radius: 12px; transition: 0.3s; }
.toggle-slider::before { content: ''; position: absolute; width: 18px; height: 18px; left: 3px; bottom: 3px; background: #fff; border-radius: 50%; transition: 0.3s; }
.toggle-switch input:checked + .toggle-slider { background: linear-gradient(135deg, var(--primary), var(--accent)); }
.toggle-switch input:checked + .toggle-slider::before { transform: translateX(20px); }

.setting-avatar { width: 36px; height: 36px; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--accent)); display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 700; color: #fff; overflow: hidden; cursor: pointer; flex-shrink: 0; }
.setting-avatar img { width: 100%; height: 100%; object-fit: cover; }
.avatar-preview-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.7); display: flex; align-items: center; justify-content: center; z-index: 3000; animation: fadeIn 0.2s ease; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.avatar-preview-card { text-align: center; max-width: 400px; width: 90%; animation: scaleIn 0.25s cubic-bezier(0.34, 1.56, 0.64, 1); }
@keyframes scaleIn { from { transform: scale(0.5); opacity: 0; } to { transform: scale(1); opacity: 1; } }
.avatar-preview-img { width: 100%; max-height: 60vh; object-fit: contain; border-radius: 16px; box-shadow: 0 8px 40px rgba(0,0,0,0.4); margin-bottom: 16px; }
.avatar-preview-actions { display: flex; gap: 12px; justify-content: center; margin-bottom: 12px; }
.preview-btn { padding: 10px 24px; border: none; border-radius: 10px; background: linear-gradient(135deg, var(--primary), var(--accent)); color: #fff; font-size: 14px; font-weight: 600; cursor: pointer; }
.close-preview { padding: 8px 24px; border: 1px solid var(--border); border-radius: 10px; background: var(--card); color: var(--text-secondary); font-size: 13px; cursor: pointer; }
</style>
