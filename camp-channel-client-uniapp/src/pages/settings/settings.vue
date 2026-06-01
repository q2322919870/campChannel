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
  position: relative;
  z-index: 1;
}

.settings-header {
  padding: 32rpx;
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  margin: 20rpx;
  border-radius: 20rpx;
  border: 1rpx solid rgba(124, 159, 203, 0.15);
}

.page-title {
  font-size: 40rpx;
  font-weight: bold;
  color: #E8EFF7;
}

.settings-section {
  margin: 0 20rpx 16rpx 20rpx;
  background: rgba(124, 159, 203, 0.08);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border-radius: 20rpx;
  border: 1rpx solid rgba(124, 159, 203, 0.15);
  overflow: hidden;
}

.section-title {
  padding: 24rpx 32rpx;
  font-size: 26rpx;
  font-weight: 600;
  color: rgba(232, 239, 247, 0.6);
  background: transparent;
  border-bottom: 1rpx solid rgba(124, 159, 203, 0.1);
}

.setting-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 28rpx 32rpx;
  border-bottom: 1rpx solid rgba(124, 159, 203, 0.08);
  transition: background 0.2s;
}

.setting-item:last-child {
  border-bottom: none;
}

.setting-item:active {
  background: rgba(124, 159, 203, 0.05);
}

.setting-label {
  font-size: 28rpx;
  color: #E8EFF7;
}

.setting-arrow {
  font-size: 36rpx;
  color: rgba(232, 239, 247, 0.4);
}

.about-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 28rpx 32rpx;
}

.about-label {
  font-size: 28rpx;
  color: #E8EFF7;
}

.about-value {
  font-size: 28rpx;
  color: rgba(232, 239, 247, 0.6);
}
</style>
