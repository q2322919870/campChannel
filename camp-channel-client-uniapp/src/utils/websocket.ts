/**
 * Centralized WebSocket Manager for WeChat Mini Program
 * Prevents multiple connections and manages lifecycle
 */

type MessageHandler = (data: any) => void

class WebSocketManager {
  private ws: any = null
  private handlers: Map<string, Set<MessageHandler>> = new Map()
  private reconnectTimer: any = null
  private isConnecting = false
  private maxReconnectAttempts = 5
  private reconnectAttempts = 0

  constructor() {
    // Singleton pattern - only one instance
  }

  /**
   * Connect to WebSocket server
   */
  public connect(url?: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.ws && this.ws.readyState === 1) {
        // Already connected
        resolve()
        return
      }

      if (this.isConnecting) {
        // Connection in progress
        reject(new Error('Connection already in progress'))
        return
      }

      this.isConnecting = true

      // Get WebSocket URL
      const storedUrl = uni.getStorageSync('api_base_url')
      const baseUrl = storedUrl || 'http://localhost:8080'
      // WeChat Mini Program only supports raw WebSocket, not STOMP/SockJS
      // Backend has /ws/raw endpoint for raw WebSocket connections
      let wsUrl = url || (baseUrl.replace('http', 'ws').replace('/api', '') + '/ws/raw')
      
      // Add JWT token to URL query parameter (backend requires ?token=xxx)
      const token = uni.getStorageSync('auth_token')
      if (token) {
        wsUrl += `?token=${token}`
      }

      console.log('[WS] Connecting to:', wsUrl)

      try {
        this.ws = uni.connectSocket({
          url: wsUrl,
          success: () => {
            console.log('[WS] Connection request sent')
          },
          fail: (err) => {
            console.warn('[WS] Connection failed (this is normal in dev if backend is not running):', err)
            this.isConnecting = false
            // Don't reject, allow graceful degradation
            resolve()
          }
        })

        // Handle connection open
        this.ws.onOpen(() => {
          console.log('[WS] Connected successfully')
          this.isConnecting = false
          this.reconnectAttempts = 0
          resolve()
        })

        // Handle messages
        this.ws.onMessage((res: any) => {
          try {
            const data = JSON.parse(res.data)
            console.log('[WS] Message received:', data.type)
            
            // Notify all handlers for this message type
            if (data.type && this.handlers.has(data.type)) {
              this.handlers.get(data.type)?.forEach(handler => {
                try {
                  handler(data)
                } catch (err) {
                  console.error('[WS] Handler error:', err)
                }
              })
            }

            // Notify wildcard handlers
            if (this.handlers.has('*')) {
              this.handlers.get('*')?.forEach(handler => {
                try {
                  handler(data)
                } catch (err) {
                  console.error('[WS] Wildcard handler error:', err)
                }
              })
            }
          } catch (err) {
            console.error('[WS] Message parse error:', err)
          }
        })

        // Handle errors
        this.ws.onError((err: any) => {
          console.error('[WS] Error:', err)
          this.isConnecting = false
          this.handleReconnect()
        })

        // Handle close
        this.ws.onClose(() => {
          console.log('[WS] Connection closed')
          this.ws = null
          this.isConnecting = false
          this.handleReconnect()
        })

      } catch (err) {
        console.error('[WS] Connection exception:', err)
        this.isConnecting = false
        reject(err)
      }
    })
  }

  /**
   * Disconnect from WebSocket server
   */
  public disconnect(): void {
    console.log('[WS] Disconnecting...')
    
    // Clear reconnect timer
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer)
      this.reconnectTimer = null
    }

    // Close connection
    if (this.ws) {
      try {
        this.ws.close()
      } catch (err) {
        console.error('[WS] Close error:', err)
      }
      this.ws = null
    }

    this.isConnecting = false
    this.reconnectAttempts = 0
  }

  /**
   * Send message through WebSocket
   */
  public send(data: any): void {
    if (!this.ws || this.ws.readyState !== 1) {
      console.warn('[WS] Not connected, cannot send message')
      return
    }

    try {
      const message = typeof data === 'string' ? data : JSON.stringify(data)
      this.ws.send({
        data: message,
        success: () => {
          console.log('[WS] Message sent')
        },
        fail: (err) => {
          console.error('[WS] Send failed:', err)
        }
      })
    } catch (err) {
      console.error('[WS] Send exception:', err)
    }
  }

  /**
   * Register message handler
   * @param messageType Message type to listen for (or '*' for all)
   * @param handler Callback function
   * @returns Unsubscribe function
   */
  public on(messageType: string, handler: MessageHandler): () => void {
    if (!this.handlers.has(messageType)) {
      this.handlers.set(messageType, new Set())
    }
    this.handlers.get(messageType)?.add(handler)
    
    console.log(`[WS] Registered handler for: ${messageType}`)

    // Return unsubscribe function
    return () => {
      this.off(messageType, handler)
    }
  }

  /**
   * Remove message handler
   */
  public off(messageType: string, handler: MessageHandler): void {
    const handlers = this.handlers.get(messageType)
    if (handlers) {
      handlers.delete(handler)
      if (handlers.size === 0) {
        this.handlers.delete(messageType)
      }
    }
  }

  /**
   * Remove all handlers for a message type
   */
  public offAll(messageType: string): void {
    this.handlers.delete(messageType)
  }

  /**
   * Check if connected
   */
  public isConnected(): boolean {
    return this.ws && this.ws.readyState === 1
  }

  /**
   * Handle reconnection
   */
  private handleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log('[WS] Max reconnection attempts reached, stopping retries')
      return
    }

    if (this.reconnectTimer) {
      return // Already scheduled
    }

    this.reconnectAttempts++
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 30000)
    
    console.log(`[WS] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`)
    
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null
      this.connect().catch(() => {
        // Error handled in connect method
      })
    }, delay)
  }

  /**
   * Get connection state
   */
  public getState(): number {
    return this.ws ? this.ws.readyState : -1
  }
}

// Singleton instance
const wsManager = new WebSocketManager()

export default wsManager
export { WebSocketManager }
