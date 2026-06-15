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
  images: string[]           // changed from single string to array
  videoUrls: string[]        // changed from videoUrl (singular) to videoUrls (array)
  topic?: string
  status: number             // 0=draft, 1=published, 2=deleted, 3=hiding...
  isPinned?: boolean         // V3.0 P1: post pinning
  isLiked?: boolean          // current user liked status (filled by /like/status)
  isFavourited?: boolean     // current user favourited status (filled by /favourite/status)
  favouriteCount?: number    // total favourites count
  likeCount: number
  editCount: number           // V3.0 P1: post edit count auto-incremented
  lastEditTime?: string      // V3.0 P1: time of last edit
  viewCount: number
  commentCount: number
  // Additional fields returned by backend for UI cards (populated via response mapper)
  author?: {                  // author object in card/list views
    id: number
    username: string
    avatar?: string
  }
  channelName?: string       // channel name shown on post card
  time?: string              // relative time display
  title?: string             // post title (auto-generated from first line)
}

export interface Channel {
  id: number
  channelCode: string
  name: string
  description?: string
  type: number
  status: number
  creatorId: number
  creatorName?: string
  // VP0-003: additional fields returned by backend for card/list views
  memberCount?: number      // total members in channel
  hasJoined?: boolean       // whether current user is a member
  unreadPosts?: number     // count of unread posts (for subscribed channels)
  coverImage?: string
  createdAt?: string
}


export interface Comment {
  id: number
  postId: number
  userId: number
  content: string
  parentId?: number
  status: number
  isLiked?: boolean     // VP0-002: current user liked status
  likeCount?: number    // VP0-002: total likes on this comment
  editCount?: number
  createTime: string
  updateTime?: string
  // UI fields returned by backend for card/list views
  username?: string     // VP0-002: commenter username
  avatar?: string       // VP0-002: commenter avatar
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
  type: number           // 1=text, 2=image, 3=video, 5=recalled
  status: number          // 0=sent, 1=delivered, 2=read
  isRead?: boolean       // VP0-003: read status of this message
  fileName?: string
  fileSize?: number
  createTime: string
  updateTime?: string
  // UI fields returned by backend for chat list views
  username?: string      // VP0-003: sender username
  avatar?: string        // VP0-003: sender avatar
}


export interface WebSocketChatMessage {
  id: number
  senderId: number
  receiverId: number
  content: string
  type: number           // 1=text, 2=image, 3=video, 5=recalled
  status: number         // delivery status
  username?: string      // sender display name
  avatar?: string        // sender avatar
  createTime: string
}

export interface WebSocketReadReceipt {
  friendId: number
  readAt: string
}

export interface WebSocketNotification {
  type: string            // system/interaction/chat
  category?: string       // reply/like/follow/message/badge...
  title: string
  content?: string
  relatedId?: string
  isRead: number          // 0=unread, 1=read
  timestamp: string
}

export interface WebSocketOnlineStatus {
  userId: number
  online: boolean
}

export type WebSocketEventTypes = 'message' | 'read_receipt' | 'notification' | 'online_status' | 'system'

export interface WebSocketPayload {
  type: WebSocketEventTypes
  data: any               // one of the above interfaces depending on `type`
  timestamp: string
}
