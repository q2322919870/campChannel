<template>
  <view class="settings-page">
    <view class="settings-header">
      <text class="page-title">设置</text>
    </view>

    <view class="settings-section">
      <view class="section-title">账号设置</view>
      <view class="setting-item" @tap="changePassword">
        <text class="setting-label">修改密码</text>
        <text class="setting-arrow">›</text>
      </view>
      <view class="setting-item" @tap="manageDevices">
        <text class="setting-label">设备管理</text>
        <text class="setting-arrow">›</text>
      </view>
    </view>

    <view class="settings-section">
      <view class="section-title">关于</view>
      <view class="about-item">
        <text class="about-label">版本</text>
        <text class="about-value">1.0.0</text>
      </view>
    </view>
  </view>
</template>

<script setup lang="ts">
function changePassword() {
  uni.navigateTo({ url: '/pages/settings/change-password' })
}

function manageDevices() {
  uni.navigateTo({ url: '/pages/settings/devices' })
}
</script>

<style scoped>
.settings-page {
  min-height: 100vh;
  background: transparent;
}

.settings-header {
  padding: 32rpx;
  background: var(--card);
  margin: 20rpx;
  border-radius: var(--radius-lg);
  border: 1rpx solid var(--card-border);
  box-shadow: var(--shadow-sm);
}

.page-title {
  font-size: 40rpx;
  font-weight: bold;
  color: var(--text);
}

.settings-section {
  margin: 0 20rpx 16rpx 20rpx;
  background: var(--card);
  border-radius: var(--radius);
  border: 1rpx solid var(--card-border);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}

.section-title {
  padding: 24rpx 32rpx;
  font-size: 26rpx;
  font-weight: 600;
  color: var(--text-muted);
  background: transparent;
  border-bottom: 1rpx solid var(--card-border);
}

.setting-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 28rpx 32rpx;
  border-bottom: 1rpx solid var(--card-border);
}

.setting-item:last-child {
  border-bottom: none;
}

.setting-item:active {
  background: var(--bg);
}

.setting-label {
  font-size: 28rpx;
  color: var(--text);
}

.setting-arrow {
  font-size: 36rpx;
  color: var(--text-muted);
}

.about-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 28rpx 32rpx;
}

.about-label {
  font-size: 28rpx;
  color: var(--text);
}

.about-value {
  font-size: 28rpx;
  color: var(--text-secondary);
}
</style>
