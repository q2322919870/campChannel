export interface User {
  id: number
  username: string
  email: string
  password?: string
  role: string
  status: number
  avatar?: string
  emailNotify?: number
  createTime?: string
  updateTime?: string
}

export interface SecurityUser {
  id: number
  username: string
  email: string
  role: string
}

export interface Post {
  id: number
  channelId: number
  userId: number
  content: string
  images?: string
  videoUrl?: string
  topic?: string
  status: number
  viewCount: number
  likeCount: number
  commentCount: number
  createTime: string
  updateTime?: string
}

export interface Channel {
  id: number
  channelCode: string
  name: string
  description?: string
  type: number
  status: number
  creatorId: number
  createTime: string
}

export interface Comment {
  id: number
  postId: number
  userId: number
  content: string
  parentId?: number
  status: number
  createTime: string
}

export interface Friendship {
  id: number
  userId: number
  friendId: number
  status: number
  applyTime: string
  approveTime?: string
}

export interface Message {
  id: number
  senderId: number
  receiverId: number
  content: string
  type: number
  status: number
  createTime: string
}

export interface Notification {
  id: number
  userId: number
  type: string
  title: string
  content?: string
  relatedId?: string
  isRead: number
  createTime: string
}
