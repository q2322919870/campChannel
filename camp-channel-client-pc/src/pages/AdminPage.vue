<template>
  <div class="admin-page">
    <div class="admin-sidebar">
      <div
        v-for="tab in adminTabs"
        :key="tab.id"
        class="admin-tab"
        :class="{ active: currentTab === tab.id }"
        @click="switchTab(tab.id)">
        <span class="tab-icon" v-html="tab.icon"></span>
        <span>{{ tab.label }}</span>
      </div>
    </div>
    <div class="admin-content">

      <!-- ===================== 仪表盘 ===================== -->
      <div v-if="currentTab === 'dashboard'" class="dashboard-content">
        <h2 class="admin-title">仪表盘</h2>
        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-value">{{ stats.users }}</div>
            <div class="stat-label">用户总数</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ stats.posts }}</div>
            <div class="stat-label">帖子总数</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ stats.channels }}</div>
            <div class="stat-label">频道总数</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ pendingCount }}</div>
            <div class="stat-label">待审核项</div>
          </div>
        </div>
        <div class="dashboard-section-title">快速入口</div>
        <div class="quick-actions">
          <div class="quick-action-card" @click="switchTab('channels')">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 9h16"/><path d="M4 15h16"/><path d="M10 3L8 21"/><path d="M16 3l-2 21"/></svg>
            <span>频道管理</span>
          </div>
          <div class="quick-action-card" @click="switchTab('review')">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
            <span>内容审核</span>
          </div>
          <div class="quick-action-card" @click="switchTab('reports')">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" y1="22" x2="4" y2="15"/></svg>
            <span>举报处理</span>
          </div>
          <div class="quick-action-card" @click="switchTab('logs')">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
            <span>操作日志</span>
          </div>
        </div>
      </div>


      <!-- ===================== 用户管理 ===================== -->
      <div v-if="currentTab === 'users'" class="users-content">
        <h2 class="admin-title">用户管理</h2>
        <table class="admin-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>用户名</th>
              <th>真实姓名</th>
              <th>邮箱</th>
              <th>角色</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="u in userList" :key="u.id">
              <td>{{ u.id }}</td>
              <td>
                <span v-if="!u.editingUsername">{{ u.username }}</span>
                <input v-else v-model="u.editUsername" class="inline-input" />
                <button v-if="!u.editingUsername" class="edit-btn" @click="startEditUsername(u)">✏️</button>
                <button v-if="u.editingUsername" class="save-btn" @click="saveUsername(u)">保存</button>
                <button v-if="u.editingUsername" class="cancel-btn" @click="cancelEditUsername(u)">取消</button>
              </td>
              <td>
                <span v-if="!u.editingRealName">{{ u.realName || '-' }}</span>
                <input v-else v-model="u.editRealName" class="inline-input" />
                <button v-if="!u.editingRealName" class="edit-btn" @click="startEditRealName(u)">✏️</button>
                <button v-if="u.editingRealName" class="save-btn" @click="saveRealName(u)">保存</button>
                <button v-if="u.editingRealName" class="cancel-btn" @click="cancelEditRealName(u)">取消</button>
              </td>
              <td>{{ u.email }}</td>
              <td>{{ u.role === 'sys_admin' ? '管理员' : '普通用户' }}</td>
              <td>
                <span class="status-badge" :class="u.status === 1 ? 'active' : 'disabled'">
                  {{ u.status === 1 ? '正常' : '禁用' }}
                </span>
              </td>
              <td>
                <button class="action-btn small" @click="toggleUserStatus(u)">
                  {{ u.status === 1 ? '禁用' : '启用' }}
                </button>
                <button class="action-btn small" style="margin-left:4px;" @click="resetUserPwd(u)">
                  重置密码
                </button>
                <button class="action-btn small danger" style="margin-left:4px;" @click="deleteUser(u)">
                  删除
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ===================== 频道管理 ===================== -->
      <div v-if="currentTab === 'channels'" class="channels-content">
        <h2 class="admin-title">频道管理</h2>
        <div class="section-card">
          <div class="section-card-title">创建频道</div>
          <div class="create-channel-form">
            <input v-model="newChannel.name" placeholder="频道名称" />
            <input v-model="newChannel.description" placeholder="频道简介" />
            <button @click="createChannel">创建频道</button>
          </div>
        </div>
        <div class="section-card">
          <div class="section-card-title">频道筛选</div>
          <div class="channel-filters">
            <select v-model="channelFilter.type" class="filter-select">
              <option value="">全部类型</option>
              <option value="1">公共频道</option>
              <option value="2">私人频道</option>
            </select>
            <input v-model="channelFilter.creatorUsername" placeholder="频道主用户名" class="filter-input" />
            <button class="filter-btn" @click="fetchChannels">筛选</button>
            <button class="filter-btn reset" @click="resetChannelFilter">重置</button>
          </div>
        </div>
        <div class="section-card">
          <div class="section-card-title">频道列表</div>
          <table class="admin-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>名称</th>
                <th>编号</th>
                <th>类型</th>
                <th>频道主</th>
                <th>状态</th>
                <th>创建时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="ch in channelList" :key="ch.id">
                <td>{{ ch.id }}</td>
                <td>{{ ch.name }}</td>
                <td><code>{{ ch.channelCode }}</code></td>
                <td>{{ ch.type === 1 ? '公共' : '私人' }}</td>
                <td>{{ ch.creatorUsername || '-' }}</td>
                <td>
                  <span class="status-badge" :class="statusClass(ch.status)">
                    {{ statusLabel(ch.status) }}
                  </span>
                </td>
                <td>{{ formatTime(ch.createTime) }}</td>
                <td>
                  <button
                    class="action-btn small"
                    :disabled="ch.status === 0"
                    @click="toggleChannelStatus(ch)">
                    {{ ch.status === 1 ? '禁用' : ch.status === 2 ? '启用' : '审核中' }}
                  </button>
                  <button class="action-btn small danger" style="margin-left:4px;" @click="deleteChannel(ch)">
                    删除
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- ===================== 内容审核 ===================== -->
      <div v-if="currentTab === 'review'" class="review-content">
        <h2 class="admin-title">内容审核</h2>
        <div class="review-tabs">
          <span :class="{ active: reviewTab === 'posts' }" @click="reviewTab = 'posts'; fetchPendingPosts()">
            帖子审核 <span v-if="pendingPosts.length" class="badge-count">{{ pendingPosts.length }}</span>
          </span>
          <span :class="{ active: reviewTab === 'comments' }" @click="reviewTab = 'comments'; fetchPendingComments()">
            评论审核 <span v-if="pendingComments.length" class="badge-count">{{ pendingComments.length }}</span>
          </span>
          <span :class="{ active: reviewTab === 'gallery' }" @click="reviewTab = 'gallery'; fetchPendingGallery()">
            画作审核 <span v-if="pendingGallery.length" class="badge-count">{{ pendingGallery.length }}</span>
          </span>
        </div>

        <div v-if="reviewTab === 'posts'" class="review-list">
          <div v-if="!pendingPosts.length" class="empty-state">暂无待审核帖子</div>
          <div v-for="p in pendingPosts" :key="p.id" class="review-item">
            <div class="review-item-body">
              <div class="review-item-meta">
                <span class="review-item-id">#{{ p.id }}</span>
                <span class="review-item-user">用户ID: {{ p.userId }}</span>
                <span class="review-item-time">{{ formatTime(p.createTime) }}</span>
              </div>
              <p class="review-item-text">{{ truncate(p.content, 200) }}</p>
              <div v-if="p.images" class="review-item-media">
                <span class="media-hint">📷 {{ parseImageCount(p.images) }} 张图片</span>
              </div>
            </div>
            <div class="review-actions">
              <button class="btn-approve" @click="approvePost(p.id, true)">通过</button>
              <button class="btn-reject" @click="approvePost(p.id, false)">拒绝</button>
            </div>
          </div>
        </div>

        <div v-if="reviewTab === 'comments'" class="review-list">
          <div v-if="!pendingComments.length" class="empty-state">暂无待审核评论</div>
          <div v-for="c in pendingComments" :key="c.id" class="review-item">
            <div class="review-item-body">
              <div class="review-item-meta">
                <span class="review-item-id">#{{ c.id }}</span>
                <span class="review-item-user">用户ID: {{ c.userId }}</span>
                <span class="review-item-time">{{ formatTime(c.createTime) }}</span>
              </div>
              <p class="review-item-text">{{ truncate(c.content, 200) }}</p>
            </div>
            <div class="review-actions">
              <button class="btn-approve" @click="approveComment(c.id, true)">通过</button>
              <button class="btn-reject" @click="approveComment(c.id, false)">拒绝</button>
            </div>
          </div>
        </div>

        <div v-if="reviewTab === 'gallery'" class="review-list">
          <div v-if="!pendingGallery.length" class="empty-state">暂无待审核画作</div>
          <div v-for="g in pendingGallery" :key="g.id" class="review-item">
            <div class="review-item-body">
              <div class="review-item-meta">
                <span class="review-item-id">#{{ g.id }}</span>
                <span class="review-item-user">作者: {{ g.username || '用户#' + g.userId }}</span>
                <span class="review-item-time">{{ formatTime(g.createTime) }}</span>
              </div>
              <img :src="g.imageUrl" class="review-gallery-img" />
              <p class="review-item-text">{{ g.title || '无标题' }}</p>
            </div>
            <div class="review-actions">
              <button class="btn-approve" @click="approveGallery(g.id, false)">确认违规→删除</button>
              <button class="btn-reject" @click="approveGallery(g.id, true)">放行</button>
            </div>
          </div>
        </div>
      </div>

      <!-- ===================== 举报处理 ===================== -->
      <div v-if="currentTab === 'reports'" class="reports-content">
        <h2 class="admin-title">举报处理</h2>
        <div v-if="!reportList.length" class="empty-state">暂无举报记录</div>
        <div v-for="r in reportList" :key="r.id" class="review-item">
          <div class="review-item-body">
            <div class="review-item-meta">
              <span class="review-item-id">#{{ r.id }}</span>
              <span class="review-item-type report-type" :class="'type-' + r.targetType">
                {{ targetTypeLabel(r.targetType) }}
              </span>
              <span class="review-item-user">举报人: {{ r.reporterId }}</span>
              <span class="review-item-time">{{ formatTime(r.createTime) }}</span>
            </div>
            <div class="report-target">目标 #{{ r.targetId }}</div>
            <p class="review-item-text">{{ r.reason }}</p>
            <div v-if="r.status !== 0" class="report-handle-info">
              <span class="status-badge" :class="r.status === 1 ? 'active' : 'disabled'">
                {{ r.status === 1 ? '已确认违规' : '已驳回' }}
              </span>
              <span v-if="r.handleNote" class="handle-note">备注: {{ r.handleNote }}</span>
            </div>
          </div>
          <div v-if="r.status === 0" class="review-actions">
            <button class="btn-approve" @click="handleReport(r.id, true)">确认违规</button>
            <button class="btn-reject" @click="handleReport(r.id, false)">驳回</button>
          </div>
        </div>
      </div>

      <!-- ===================== 树洞管理 ===================== -->
      <div v-if="currentTab === 'treehole'" class="treehole-content">
        <h2 class="admin-title">树洞告白管理</h2>
        <div class="treehole-stats">
          <div class="stat-card">
            <div class="stat-value">{{ treeHolePosts.length }}</div>
            <div class="stat-label">总告白数</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ treeHolePosts.filter(p => p.status === 1).length }}</div>
            <div class="stat-label">正常显示</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ treeHolePosts.filter(p => p.status === 2).length }}</div>
            <div class="stat-label">已下架</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ treeHolePosts.filter(p => isExpired(p)).length }}</div>
            <div class="stat-label">已过期</div>
          </div>
        </div>
        
        <div class="treehole-filters">
          <select v-model="treeHoleFilter" class="filter-select">
            <option value="all">全部</option>
            <option value="active">正常显示</option>
            <option value="removed">已下架</option>
            <option value="expired">已过期</option>
          </select>
        </div>

        <div v-if="!filteredTreeHolePosts.length" class="empty-state">暂无告白记录</div>
        <div v-for="post in filteredTreeHolePosts" :key="post.id" class="treehole-item">
          <div class="treehole-item-header">
            <span class="treehole-item-id">#{{ post.id }}</span>
            <span class="treehole-item-status status-badge" :class="getStatusClass(post)">
              {{ getStatusText(post) }}
            </span>
            <span class="treehole-item-time">{{ formatTime(post.createTime) }}</span>
            <span v-if="post.expireTime" class="treehole-item-expire">
              过期: {{ formatTime(post.expireTime) }}
            </span>
          </div>
          <div class="treehole-item-content">{{ post.content }}</div>
          <div class="treehole-item-meta">
            <span>发布者: {{ post.userId }}</span>
            <span>浏览: {{ post.viewCount || 0 }}</span>
            <span>点赞: {{ post.likeCount || 0 }}</span>
          </div>
          <div v-if="post.status === 1" class="treehole-item-actions">
            <button class="action-btn small danger" @click="removeTreeHolePost(post.id)">
              下架删除
            </button>
          </div>
        </div>
      </div>

      <!-- ===================== 操作日志 ===================== -->
      <div v-if="currentTab === 'logs'" class="logs-content">
        <h2 class="admin-title">操作日志</h2>
        <div class="log-filters">
          <input v-model="logFilter.userId" placeholder="用户ID" type="number" />
          <input v-model="logFilter.module" placeholder="模块名称" />
          <button class="filter-btn" @click="fetchLogs">筛选</button>
          <button class="filter-btn reset" @click="resetLogFilter">重置</button>
        </div>
        <table class="admin-table">
          <thead>
            <tr>
              <th>时间</th>
              <th>用户ID</th>
              <th>模块</th>
              <th>操作</th>
              <th>描述</th>
              <th>IP</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="!logList.length">
              <td colspan="6" class="empty-cell">暂无日志记录</td>
            </tr>
            <tr v-for="log in logList" :key="log.id">
              <td class="log-time">{{ formatTime(log.createTime) }}</td>
              <td>{{ log.userId }}</td>
              <td><span class="module-tag">{{ log.module || '-' }}</span></td>
              <td>{{ log.action || '-' }}</td>
              <td class="log-desc">{{ log.description || '-' }}</td>
              <td class="log-ip">{{ log.ipAddress || '-' }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- ===================== 公告发布 ===================== -->
      <div v-if="currentTab === 'announcement'" class="announcement-content">
        <h2 class="admin-title">发布全站公告</h2>
        <div class="announcement-form">
          <input v-model="announcementTitle" placeholder="公告标题 *" />
          <textarea v-model="announcementContent" placeholder="公告内容..." rows="6"></textarea>
          <p v-if="announceError" class="error-msg">{{ announceError }}</p>
          <button class="publish-btn" :disabled="!announcementTitle.trim() || announceLoading" @click="publishAnnouncement">
            {{ announceLoading ? '发布中...' : '发布公告' }}
          </button>
        </div>
      </div>

      <!-- ===================== 画廊管理 ===================== -->
      <div v-if="currentTab === 'gallery-mgmt'" class="gallery-mgmt-content">
        <h2 class="admin-title">画廊管理</h2>
        <div class="section-card">
          <div class="section-card-title">画廊列表（{{ galleryList.length }}）</div>
          <div v-if="galleryList.length === 0" class="empty-state">暂无画作</div>
          <div v-else class="gallery-admin-grid">
            <div v-for="item in galleryList" :key="item.id" class="gallery-admin-item">
              <img :src="item.imageUrl" class="gallery-admin-img" />
              <div class="gallery-admin-info">
                <div class="gallery-admin-title">{{ item.title || '无标题' }}</div>
                <div class="gallery-admin-user">作者: {{ item.username || '用户#' + item.userId }}</div>
                <div class="gallery-admin-time">{{ formatTime(item.createTime) }}</div>
              </div>
              <button class="action-btn small danger" @click="deleteGalleryItem(item)">删除</button>
            </div>
          </div>
        </div>
      </div>

    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { api } from '../api/client'

const currentTab = ref('dashboard')
const reviewTab = ref('posts')

const stats = reactive({ users: 0, posts: 0, channels: 0 })
const pendingCount = ref(0)

const userList = ref<any[]>([])

const newChannel = reactive({ name: '', description: '' })
const channelList = ref<any[]>([])
const channelFilter = reactive({ type: '', creatorUsername: '' })

const pendingPosts = ref<any[]>([])
const pendingComments = ref<any[]>([])
const pendingGallery = ref<any[]>([])

const reportList = ref<any[]>([])

const treeHolePosts = ref<any[]>([])
const treeHoleFilter = ref('all')

const logList = ref<any[]>([])
const logFilter = reactive({ userId: '', module: '' })

const announcementTitle = ref('')
const announcementContent = ref('')
const announceLoading = ref(false)
const announceError = ref('')

async function publishAnnouncement() {
  if (!announcementTitle.value.trim()) return
  announceLoading.value = true
  announceError.value = ''
  try {
    const res = await api.post('/admin/announcement', {
      title: announcementTitle.value,
      content: announcementContent.value,
    })
    if (res.data.code === 200) {
      alert(res.data.message || '公告已发布')
      announcementTitle.value = ''
      announcementContent.value = ''
    } else {
      announceError.value = res.data.message || '发布失败'
    }
  } catch (e: any) {
    announceError.value = e.response?.data?.message || '发布失败'
  } finally {
    announceLoading.value = false
  }
}

const adminTabs = [
  {
    id: 'dashboard',
    label: '仪表盘',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>',
  },
  {
    id: 'users',
    label: '用户管理',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>',
  },
  {
    id: 'channels',
    label: '频道管理',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 9h16"/><path d="M4 15h16"/><path d="M10 3L8 21"/><path d="M16 3l-2 21"/></svg>',
  },
  {
    id: 'review',
    label: '内容审核',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 11 12 14 22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>',
  },
  {
    id: 'reports',
    label: '举报处理',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" y1="22" x2="4" y2="15"/></svg>',
  },
  {
    id: 'treehole',
    label: '树洞管理',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z"/><path d="M12 8v4l3 3"/></svg>',
  },
  {
    id: 'logs',
    label: '操作日志',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>',
  },
  {
    id: 'announcement',
    label: '公告发布',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 2L11 13"/><path d="M22 2l-7 20-4-9-9-4 20-7z"/></svg>',
  },
  {
    id: 'gallery-mgmt',
    label: '画廊管理',
    icon: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>',
  },
]

function switchTab(tab: string) {
  currentTab.value = tab
  if (tab === 'dashboard') fetchDashboard()
  else if (tab === 'users') fetchUsers()
  else if (tab === 'channels') fetchChannels()
  else if (tab === 'review') { reviewTab.value = 'posts'; fetchPendingPosts(); fetchPendingComments() }
  else if (tab === 'reports') fetchReports()
  else if (tab === 'treehole') fetchTreeHolePosts()
  else if (tab === 'logs') fetchLogs()
  else if (tab === 'announcement') {} // no fetch needed
  else if (tab === 'gallery-mgmt') fetchGalleryList()
}

function statusClass(status: number): string {
  if (status === 1) return 'active'
  if (status === 0) return 'pending'
  return 'disabled'
}

function statusLabel(status: number): string {
  if (status === 1) return '正常'
  if (status === 0) return '待审核'
  return '禁用'
}

function targetTypeLabel(type: string): string {
  const map: Record<string, string> = { post: '帖子', comment: '评论', message: '消息' }
  return map[type] || type
}

// 树洞管理相关函数
function isExpired(post: any): boolean {
  if (!post.expireTime) return false
  return new Date(post.expireTime) < new Date()
}

function getStatusClass(post: any): string {
  if (post.status === 2) return 'disabled'
  if (isExpired(post)) return 'expired'
  return 'active'
}

function getStatusText(post: any): string {
  if (post.status === 2) return '已下架'
  if (isExpired(post)) return '已过期'
  return '正常'
}

const filteredTreeHolePosts = computed(() => {
  const posts = treeHolePosts.value
  switch (treeHoleFilter.value) {
    case 'active':
      return posts.filter(p => p.status === 1 && !isExpired(p))
    case 'removed':
      return posts.filter(p => p.status === 2)
    case 'expired':
      return posts.filter(p => isExpired(p))
    default:
      return posts
  }
})

async function fetchTreeHolePosts() {
  try {
    // 获取所有树洞帖子（包括已过期的）
    const res = await api.get('/posts/tree-hole', { params: { page: 1, size: 200 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) {
      treeHolePosts.value = res.data.data
    }
  } catch (e) {
    console.error('Failed to fetch tree hole posts:', e)
  }
}

async function removeTreeHolePost(postId: number) {
  if (!confirm('确定要下架删除这个告白吗？')) return
  
  try {
    const res = await api.delete(`/posts/${postId}`)
    if (res.data.code === 200) {
      alert('已下架删除')
      await fetchTreeHolePosts()
    }
  } catch (e) {
    console.error('Failed to remove post:', e)
    alert('删除失败')
  }
}

function parseImageCount(images: any): number {
  if (!images) return 0
  try { return JSON.parse(images).length } catch { return 0 }
}

function truncate(text: string, max: number): string {
  if (!text) return ''
  return text.length > max ? text.slice(0, max) + '...' : text
}

function formatTime(t: string | null | undefined): string {
  if (!t) return '-'
  try {
    const d = new Date(t)
    const pad = (n: number) => n.toString().padStart(2, '0')
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
  } catch { return t }
}

async function fetchDashboard() {
  const results = await Promise.allSettled([
    api.get('/admin/users', { params: { page: 1, size: 1 } }),
    api.get('/admin/posts/pending', { params: { page: 1, size: 1 } }),
    api.get('/channels/search'),
  ])
  const userRes = results[0]
  if (userRes.status === 'fulfilled' && userRes.value.data.code === 200) {
    stats.users = userRes.value.data.data?.length || 256
  }
  const pendingRes = results[1]
  if (pendingRes.status === 'fulfilled' && pendingRes.value.data.code === 200) {
    const data = pendingRes.value.data.data
    pendingCount.value = Array.isArray(data) ? data.length : 0
  }
  const channelRes = results[2]
  if (channelRes.status === 'fulfilled' && channelRes.value.data.code === 200) {
    const data = channelRes.value.data.data
    stats.channels = Array.isArray(data) ? data.length : 0
  }
}

async function fetchUsers() {
  try {
    const res = await api.get('/admin/users', { params: { page: 1, size: 50 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) userList.value = res.data.data
  } catch {}
}

async function toggleUserStatus(u: any) {
  try {
    const res = await api.put(`/admin/users/${u.id}/status`, { status: u.status === 1 ? 0 : 1 })
    if (res.data.code === 200) u.status = u.status === 1 ? 0 : 1
  } catch {}
}

async function resetUserPwd(u: any) {
  try {
    const res = await api.post(`/admin/users/${u.id}/reset-password`)
    if (res.data.code === 200) alert(res.data.message || '密码已重置为 123456')
  } catch {}
}

async function deleteUser(u: any) {
  if (!confirm(`确认删除用户 "${u.username}"（ID: ${u.id}）？此操作不可撤销！`)) return
  try {
    const res = await api.delete(`/admin/users/${u.id}`)
    if (res.data.code === 200) {
      userList.value = userList.value.filter(item => item.id !== u.id)
    } else {
      alert(res.data.message || '删除失败')
    }
  } catch (e: any) {
    alert(e.response?.data?.message || '删除失败')
  }
}

function startEditUsername(u: any) {
  u.editingUsername = true
  u.editUsername = u.username
}

async function saveUsername(u: any) {
  if (!u.editUsername || !u.editUsername.trim()) return
  try {
    const res = await api.put(`/admin/users/${u.id}`, { username: u.editUsername.trim() })
    if (res.data.code === 200) {
      u.username = u.editUsername.trim()
      u.editingUsername = false
    } else {
      alert(res.data.message || '修改失败')
    }
  } catch (e: any) {
    alert(e.response?.data?.message || '修改失败')
  }
}

function cancelEditUsername(u: any) {
  u.editingUsername = false
}

function startEditRealName(u: any) {
  u.editingRealName = true
  u.editRealName = u.realName || ''
}

async function saveRealName(u: any) {
  try {
    const res = await api.put(`/admin/users/${u.id}`, { realName: u.editRealName.trim() })
    if (res.data.code === 200) {
      u.realName = u.editRealName.trim()
      u.editingRealName = false
    } else {
      alert(res.data.message || '修改失败')
    }
  } catch (e: any) {
    alert(e.response?.data?.message || '修改失败')
  }
}

function cancelEditRealName(u: any) {
  u.editingRealName = false
}

async function fetchChannels() {
  try {
    const params: Record<string, any> = {}
    if (channelFilter.type) params.type = Number(channelFilter.type)
    if (channelFilter.creatorUsername) params.creatorUsername = channelFilter.creatorUsername
    const res = await api.get('/admin/channels', { params })
    if (res.data.code === 200 && Array.isArray(res.data.data)) channelList.value = res.data.data
  } catch {}
}

function resetChannelFilter() {
  channelFilter.type = ''
  channelFilter.creatorUsername = ''
  fetchChannels()
}

async function createChannel() {
  if (!newChannel.name) return
  try {
    const res = await api.post('/channels', {
      name: newChannel.name,
      description: newChannel.description,
    })
    if (res.data.code === 200) {
      newChannel.name = ''
      newChannel.description = ''
      fetchChannels()
    }
  } catch {}
}

async function toggleChannelStatus(ch: any) {
  const targetStatus = ch.status === 1 ? 2 : 1
  try {
    const res = await api.put(`/admin/channels/${ch.id}/status`, { status: targetStatus })
    if (res.data.code === 200) ch.status = targetStatus
  } catch {}
}

async function deleteChannel(ch: any) {
  if (!confirm(`确认删除频道 "${ch.name}"（ID: ${ch.id}）？此操作不可撤销！`)) return
  try {
    const res = await api.delete(`/admin/channels/${ch.id}`)
    if (res.data.code === 200) {
      channelList.value = channelList.value.filter(item => item.id !== ch.id)
    } else {
      alert(res.data.message || '删除失败')
    }
  } catch (e: any) {
    alert(e.response?.data?.message || '删除失败')
  }
}

async function fetchPendingPosts() {
  try {
    const res = await api.get('/admin/posts/pending', { params: { page: 1, size: 20 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) pendingPosts.value = res.data.data
  } catch {}
}

async function approvePost(id: number, approved: boolean) {
  try {
    const res = await api.post(`/admin/posts/${id}/approve`, { approved })
    if (res.data.code === 200) pendingPosts.value = pendingPosts.value.filter(p => p.id !== id)
  } catch {}
}

async function fetchPendingComments() {
  try {
    const res = await api.get('/admin/comments/pending', { params: { page: 1, size: 20 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) pendingComments.value = res.data.data
  } catch {}
}

async function approveComment(id: number, approved: boolean) {
  try {
    const res = await api.post(`/admin/comments/${id}/approve`, { approved })
    if (res.data.code === 200) pendingComments.value = pendingComments.value.filter(c => c.id !== id)
  } catch {}
}

async function fetchPendingGallery() {
  try {
    const res = await api.get('/gallery/pending')
    if (res.data.code === 200 && Array.isArray(res.data.data)) pendingGallery.value = res.data.data
  } catch {}
}

async function approveGallery(id: number, approved: boolean) {
  try {
    const res = await api.post(`/gallery/${id}/approve`, { approved })
    if (res.data.code === 200) {
      pendingGallery.value = pendingGallery.value.filter(g => g.id !== id)
    }
  } catch {}
}

async function fetchReports() {
  try {
    const res = await api.get('/reports', { params: { page: 1, size: 50 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) reportList.value = res.data.data
  } catch {}
}

async function handleReport(id: number, approved: boolean) {
  try {
    const res = await api.post(`/reports/${id}/handle`, { approved, note: '' })
    if (res.data.code === 200) reportList.value = reportList.value.filter(r => r.id !== id)
  } catch {}
}

async function fetchLogs() {
  try {
    const params: Record<string, any> = { page: 1, size: 50 }
    if (logFilter.userId) params.userId = Number(logFilter.userId)
    if (logFilter.module) params.module = logFilter.module
    const res = await api.get('/admin/logs', { params })
    if (res.data.code === 200 && Array.isArray(res.data.data)) logList.value = res.data.data
  } catch {}
}

function resetLogFilter() {
  logFilter.userId = ''
  logFilter.module = ''
  fetchLogs()
}

const galleryList = ref<any[]>([])

async function fetchGalleryList() {
  try {
    const res = await api.get('/gallery', { params: { page: 1, size: 100 } })
    if (res.data.code === 200 && Array.isArray(res.data.data)) galleryList.value = res.data.data
  } catch {}
}

async function deleteGalleryItem(item: any) {
  if (!confirm(`确认删除画作 "${item.title || '无标题'}" ？`)) return
  try {
    const res = await api.delete(`/gallery/admin/${item.id}`)
    if (res.data.code === 200) {
      galleryList.value = galleryList.value.filter(g => g.id !== item.id)
    } else { alert(res.data.message || '删除失败') }
  } catch (e: any) { alert(e.response?.data?.message || '删除失败') }
}

onMounted(() => {
  fetchDashboard()
  fetchUsers()
})
</script>

<style scoped>
.admin-page {
  display: flex;
  gap: 0;
  height: calc(100vh - 64px);
}

.admin-sidebar {
  width: 200px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 8px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  flex-shrink: 0;
  overflow-y: auto;
}

.admin-tab {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  border-radius: 10px;
  cursor: pointer;
  font-size: 13px;
  color: var(--on-surface-variant);
  transition: all 0.2s;
}

.admin-tab:hover {
  background: rgba(255, 255, 255, 0.04);
  color: var(--on-surface);
}

.admin-tab.active {
  background: rgba(124, 159, 203, 0.1);
  color: var(--primary);
  font-weight: 600;
}

.tab-icon {
  display: flex;
  align-items: center;
}

.admin-content {
  flex: 1;
  padding: 0 24px;
  overflow-y: auto;
}

.admin-title {
  font-size: 22px;
  font-weight: 700;
  margin-bottom: 24px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
}

.stat-card {
  padding: 24px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  text-align: center;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  color: var(--primary);
  margin-bottom: 4px;
}

.stat-label {
  font-size: 13px;
  color: var(--on-surface-variant);
}

.dashboard-section-title {
  font-size: 16px;
  font-weight: 600;
  margin: 28px 0 16px;
  color: var(--on-surface);
}

.quick-actions {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
}

.quick-action-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 20px 12px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 14px;
  cursor: pointer;
  transition: all 0.2s;
  color: var(--on-surface-variant);
  font-size: 13px;
}

.quick-action-card:hover {
  border-color: var(--primary);
  color: var(--primary);
  background: rgba(124, 159, 203, 0.05);
}

.admin-table {
  width: 100%;
  border-collapse: collapse;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  overflow: hidden;
}

.admin-table th,
.admin-table td {
  padding: 12px 16px;
  text-align: left;
  font-size: 13px;
  border-bottom: 1px solid var(--outline-variant);
}

.admin-table th {
  font-weight: 600;
  color: var(--on-surface-variant);
  background: rgba(255, 255, 255, 0.02);
  white-space: nowrap;
}

.admin-table td code {
  font-size: 12px;
  background: rgba(124, 159, 203, 0.08);
  padding: 2px 6px;
  border-radius: 4px;
  color: var(--primary);
}

.status-badge {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 500;
}

.status-badge.active {
  background: rgba(74, 222, 128, 0.15);
  color: #4ade80;
}

.status-badge.disabled {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.status-badge.pending {
  background: rgba(251, 191, 36, 0.15);
  color: #fbbf24;
}

.action-btn.small {
  padding: 4px 12px;
  font-size: 12px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  color: var(--on-surface);
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.15s;
}

.action-btn.small:hover {
  border-color: var(--primary);
  color: var(--primary);
}

.action-btn.small:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.action-btn.danger { border-color: rgba(255,107,107,0.3); color: #ff6b6b; }
.action-btn.danger:hover { background: rgba(255,107,107,0.1); }

.section-card {
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 16px;
  padding: 20px;
  margin-bottom: 20px;
}

.section-card-title {
  font-size: 15px;
  font-weight: 600;
  margin-bottom: 14px;
  color: var(--on-surface);
}

.create-channel-form {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.create-channel-form input,
.create-channel-form select {
  flex: 1;
  min-width: 160px;
  padding: 10px 14px;
  border: 1px solid var(--outline-variant);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.03);
  color: var(--on-surface);
  font-size: 13px;
  outline: none;
  transition: border-color 0.2s;
}

.create-channel-form input:focus,
.create-channel-form select:focus {
  border-color: var(--primary);
}

.create-channel-form select {
  cursor: pointer;
  appearance: auto;
}

.create-channel-form button {
  padding: 10px 24px;
  border: none;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--primary), var(--secondary));
  color: #fff;
  font-weight: 600;
  cursor: pointer;
  font-size: 13px;
  white-space: nowrap;
  transition: opacity 0.2s;
}

.create-channel-form button:hover {
  opacity: 0.9;
}

.review-tabs {
  display: flex;
  gap: 4px;
  margin-bottom: 16px;
  background: var(--surface);
  border-radius: 10px;
  padding: 4px;
  width: fit-content;
  border: 1px solid var(--outline-variant);
}

.review-tabs span {
  position: relative;
  padding: 8px 20px;
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
  color: var(--on-surface-variant);
}

.review-tabs span.active {
  background: rgba(124, 159, 203, 0.15);
  color: var(--primary);
  font-weight: 600;
}

.badge-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  height: 18px;
  padding: 0 5px;
  border-radius: 9px;
  background: var(--primary);
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  margin-left: 6px;
}

.review-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.review-item {
  padding: 16px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 12px;
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}

.review-item-body {
  flex: 1;
  min-width: 0;
}

.review-item-meta {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
  flex-wrap: wrap;
}

.review-item-id {
  font-weight: 600;
  color: var(--on-surface);
  font-size: 12px;
}

.review-item-user,
.review-item-time {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.review-item-text {
  font-size: 14px;
  color: var(--on-surface);
  margin: 4px 0 0;
  line-height: 1.6;
  word-break: break-word;
}

.review-item-media {
  margin-top: 6px;
}

.media-hint {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.report-target {
  font-size: 12px;
  color: var(--on-surface-variant);
  margin-top: 2px;
}

.report-type {
  display: inline-block;
  padding: 1px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 500;
}

.report-type.type-post {
  background: rgba(124, 159, 203, 0.15);
  color: var(--primary);
}

.report-type.type-comment {
  background: rgba(74, 222, 128, 0.15);
  color: #4ade80;
}

.report-type.type-message {
  background: rgba(251, 191, 36, 0.15);
  color: #fbbf24;
}

.report-handle-info {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 8px;
}

.handle-note {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.review-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
  align-items: center;
}

.review-actions button {
  padding: 6px 16px;
  border: none;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.15s;
}

.review-actions button:hover {
  opacity: 0.8;
}

.btn-approve {
  background: rgba(74, 222, 128, 0.15);
  color: #4ade80;
}

.btn-reject {
  background: rgba(255, 107, 107, 0.15);
  color: #ff6b6b;
}

.empty-state {
  text-align: center;
  padding: 48px 16px;
  color: var(--on-surface-variant);
  font-size: 14px;
  background: var(--surface);
  border: 1px solid var(--outline-variant);
  border-radius: 12px;
}

.log-filters {
  display: flex;
  gap: 8px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.log-filters input {
  padding: 8px 14px;
  border: 1px solid var(--outline-variant);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.03);
  color: var(--on-surface);
  font-size: 13px;
  outline: none;
  width: 140px;
  transition: border-color 0.2s;
}

.log-filters input:focus {
  border-color: var(--primary);
}

.filter-btn {
  padding: 8px 18px;
  border: 1px solid var(--outline-variant);
  border-radius: 10px;
  background: var(--surface);
  color: var(--on-surface);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;
}

.filter-btn:hover {
  border-color: var(--primary);
  color: var(--primary);
}

.filter-btn.reset:hover {
  border-color: #ff6b6b;
  color: #ff6b6b;
}

.empty-cell {
  text-align: center;
  color: var(--on-surface-variant);
  padding: 32px 16px !important;
}

.log-time {
  white-space: nowrap;
  font-size: 12px;
  color: var(--on-surface-variant);
}

.log-desc {
  max-width: 280px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.log-ip {
  font-size: 12px;
  color: var(--on-surface-variant);
}

.module-tag {
  display: inline-block;
  padding: 1px 8px;
  border-radius: 4px;
  font-size: 11px;
  background: rgba(124, 159, 203, 0.1);
  color: var(--primary);
}

.channel-filters {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  align-items: center;
}

.filter-select {
  padding: 8px 14px;
  border: 1px solid var(--outline-variant);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.03);
  color: var(--on-surface);
  font-size: 13px;
  outline: none;
  cursor: pointer;
  transition: border-color 0.2s;
}

.filter-select:focus {
  border-color: var(--primary);
}

.filter-input {
  padding: 8px 14px;
  border: 1px solid var(--outline-variant);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.03);
  color: var(--on-surface);
  font-size: 13px;
  outline: none;
  width: 160px;
  transition: border-color 0.2s;
}

.filter-input:focus {
  border-color: var(--primary);
}

.inline-input {
  padding: 4px 8px;
  border: 1px solid var(--primary);
  border-radius: 6px;
  background: rgba(124, 159, 203, 0.08);
  color: var(--on-surface);
  font-size: 13px;
  outline: none;
  width: 120px;
}

.edit-btn {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
  padding: 2px 6px;
  border-radius: 4px;
  transition: background 0.15s;
}

.edit-btn:hover {
  background: rgba(124, 159, 203, 0.15);
}

.save-btn {
  padding: 2px 10px;
  border: 1px solid #4ade80;
  border-radius: 6px;
  background: rgba(74, 222, 128, 0.1);
  color: #4ade80;
  font-size: 12px;
  cursor: pointer;
  margin-left: 4px;
  transition: all 0.15s;
}

.save-btn:hover {
  background: rgba(74, 222, 128, 0.2);
}

.cancel-btn {
  padding: 2px 10px;
  border: 1px solid #ff6b6b;
  border-radius: 6px;
  background: rgba(255, 107, 107, 0.1);
  color: #ff6b6b;
  font-size: 12px;
  cursor: pointer;
  margin-left: 4px;
  transition: all 0.15s;
}

.cancel-btn:hover {
  background: rgba(255, 107, 107, 0.2);
}

@media (max-width: 1024px) {
  .stats-grid,
  .quick-actions {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .admin-page {
    flex-direction: column;
    height: auto;
  }

  .admin-sidebar {
    width: 100%;
    flex-direction: row;
    overflow-x: auto;
    border-radius: 12px;
  }

  .admin-content {
    padding: 16px 0;
  }

  .admin-table {
    font-size: 12px;
  }

  .admin-table th,
  .admin-table td {
    padding: 8px 10px;
  }

  .review-item {
    flex-direction: column;
  }

  .review-actions {
    width: 100%;
    justify-content: flex-end;
  }

  .create-channel-form {
    flex-direction: column;
  }

  .create-channel-form input,
  .create-channel-form select {
    min-width: auto;
  }

  .stats-grid,
  .quick-actions {
    grid-template-columns: repeat(2, 1fr);
  }
}

.announcement-form { max-width: 500px; display: flex; flex-direction: column; gap: 12px; background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 16px; padding: 24px; }
.announcement-form input, .announcement-form textarea { padding: 12px 16px; border: 1px solid var(--outline-variant); border-radius: 12px; background: rgba(255,255,255,0.03); color: var(--on-surface); font-size: 14px; outline: none; font-family: inherit; }
.announcement-form input:focus, .announcement-form textarea:focus { border-color: var(--primary); }
.announcement-form textarea { resize: vertical; }
.publish-btn { padding: 14px; border: none; border-radius: 12px; background: linear-gradient(135deg, var(--primary), var(--secondary)); color: #fff; font-size: 15px; font-weight: 600; cursor: pointer; }
.publish-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.review-gallery-img { width: 120px; height: 80px; object-fit: cover; border-radius: 8px; margin: 8px 0; }

/* 树洞管理样式 */
.treehole-content { display: flex; flex-direction: column; gap: 24px; }
.treehole-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; }
.treehole-filters { display: flex; gap: 12px; align-items: center; }
.filter-select { padding: 8px 16px; border: 1px solid var(--outline-variant); border-radius: 12px; background: var(--surface); color: var(--on-surface); font-size: 14px; outline: none; cursor: pointer; }
.filter-select:focus { border-color: var(--primary); }
.treehole-item { background: var(--surface); border: 1px solid var(--outline-variant); border-radius: 16px; padding: 20px; display: flex; flex-direction: column; gap: 12px; }
.treehole-item-header { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
.treehole-item-id { font-weight: 600; color: var(--primary); font-size: 14px; }
.treehole-item-status { font-size: 12px; padding: 4px 10px; border-radius: 8px; }
.treehole-item-status.active { background: rgba(76, 175, 80, 0.1); color: #4caf50; }
.treehole-item-status.expired { background: rgba(255, 152, 0, 0.1); color: #ff9800; }
.treehole-item-status.disabled { background: rgba(244, 67, 54, 0.1); color: #f44336; }
.treehole-item-time { font-size: 12px; color: var(--on-surface-variant); }
.treehole-item-expire { font-size: 12px; color: #ff9800; }
.treehole-item-content { font-size: 15px; line-height: 1.6; color: var(--on-surface); background: rgba(255,255,255,0.02); padding: 12px; border-radius: 8px; }
.treehole-item-meta { display: flex; gap: 16px; font-size: 13px; color: var(--on-surface-variant); }
.treehole-item-actions { display: flex; gap: 8px; justify-content: flex-end; padding-top: 8px; border-top: 1px solid var(--outline-variant); }
</style>
