import * as THREE from 'three'

export interface Gallery3DItem {
  id: number
  imageUrl: string
  videoUrl?: string
  mediaType?: number // 1-图片, 2-视频
  title?: string
  username?: string
  userId?: number
}

export class Post3DGallery {
  private scene: THREE.Scene
  private camera: THREE.PerspectiveCamera
  private renderer: THREE.WebGLRenderer
  private group: THREE.Group
  private animationId = 0
  private rotationSpeed = 0
  private targetRotation = 0
  private items: Gallery3DItem[] = []
  private meshes: THREE.Mesh[] = []
  private textures: Map<number, THREE.Texture> = new Map()
  private videoElements: Map<number, HTMLVideoElement> = new Map()
  private videoTextures: Map<number, THREE.VideoTexture> = new Map()
  private selectedId: number | null = null
  private paused = false
  private onClickBound: ((e: MouseEvent) => void) | null = null
  private onSelectCallback: ((item: Gallery3DItem) => void) | null = null
  private frontItemIndex = -1
  private pColor: THREE.Color
  private touchStartX = 0
  private onTouchMoveBound: ((e: TouchEvent) => void) | null = null
  private onTouchEndBound: ((e: TouchEvent) => void) | null = null

  constructor(container: HTMLElement, items: Gallery3DItem[], colors: { primary: string; secondary: string }) {
    this.items = items
    this.scene = new THREE.Scene()
    const w = container.clientWidth
    const h = container.clientHeight
    this.camera = new THREE.PerspectiveCamera(45, w / h, 0.1, 100)
    this.camera.position.set(0, 0, 12)

    this.renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true })
    this.renderer.setSize(w, h)
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    container.appendChild(this.renderer.domElement)

    this.group = new THREE.Group()
    this.scene.add(this.group)

    const pColor = new THREE.Color(colors.primary)
    this.pColor = pColor
    const aColor = new THREE.Color(colors.secondary)

    items.forEach((item, i) => {
      const angle = (Math.PI * 2 * i) / items.length
      const radius = 4.5
      const x = Math.sin(angle) * radius
      const z = Math.cos(angle) * radius

      let texture: THREE.Texture

      // 检查是否为视频
      const isVideo = item.mediaType === 2 || (item.videoUrl && !item.imageUrl)
      if (isVideo && item.videoUrl) {
        // 创建视频元素
        const video = document.createElement('video')
        video.src = item.videoUrl
        video.crossOrigin = 'anonymous'
        video.loop = true
        video.muted = true
        video.playsInline = true
        video.autoplay = true
        video.style.display = 'none'
        document.body.appendChild(video)

        this.videoElements.set(item.id, video)

        // 创建视频纹理
        const videoTexture = new THREE.VideoTexture(video)
        videoTexture.minFilter = THREE.LinearFilter
        videoTexture.magFilter = THREE.LinearFilter
        videoTexture.format = THREE.RGBAFormat
        this.videoTextures.set(item.id, videoTexture)

        texture = videoTexture
      } else {
        // 图片纹理
        texture = new THREE.TextureLoader().load(item.imageUrl)
        this.textures.set(item.id, texture)
      }
      const geo = new THREE.PlaneGeometry(2.4, 2.4 * 0.75)
      // 翻转 UV 坐标，让图片正面朝向观察者（3D 画廊中图片朝内，需要翻转 UV）
      const uvAttr = geo.attributes.uv
      for (let i = 0; i < uvAttr.count; i++) {
        uvAttr.setXY(i, 1 - uvAttr.getX(i), uvAttr.getY(i))
      }
      const mat = new THREE.ShaderMaterial({
        uniforms: {
          uTexture: { value: texture },
          uBorderColor: { value: pColor },
          uTime: { value: 0 },
          uGlow: { value: aColor },
        },
        vertexShader: `
          varying vec2 vUv;
          void main() {
            vUv = uv;
            gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
          }
        `,
        fragmentShader: `
          precision highp float;
          varying vec2 vUv;
          uniform sampler2D uTexture;
          uniform vec3 uBorderColor;
          uniform float uTime;
          uniform vec3 uGlow;

          void main() {
            vec2 uv = vUv;
            float border = 0.025;
            float b = smoothstep(0.0, border, uv.x) * smoothstep(1.0, 1.0 - border, uv.x)
                    * smoothstep(0.0, border, uv.y) * smoothstep(1.0, 1.0 - border, uv.y);

            vec4 texColor = texture2D(uTexture, uv);
            float pulse = sin(uTime * 0.5 + uv.x * 6.28) * 0.06 + 0.06;
            vec3 col = mix(texColor.rgb, uGlow, pulse * (1.0 - b));

            float vignette = 1.0 - length(uv - 0.5) * 0.4;
            col *= vignette;

            gl_FragColor = vec4(col, b * 0.92 + 0.08);
          }
        `,
        transparent: true,
        side: THREE.DoubleSide,
      })

      const mesh = new THREE.Mesh(geo, mat)
      mesh.position.set(x, 0, z)
      mesh.lookAt(0, 0, 0)
      this.group.add(mesh)
      this.meshes.push(mesh)

      const edgeGeo = new THREE.EdgesGeometry(geo)
      const edgeMat = new THREE.LineBasicMaterial({ color: pColor, transparent: true, opacity: 0.4 })
      const edge = new THREE.LineSegments(edgeGeo, edgeMat)
      edge.position.copy(mesh.position)
      edge.quaternion.copy(mesh.quaternion)
      this.group.add(edge)
    })

    container.addEventListener('wheel', this.onWheel, { passive: false })
    this.onClickBound = this.onClick.bind(this)
    container.addEventListener('click', this.onClickBound)
    this.onTouchMoveBound = this.onTouchMove.bind(this)
    this.onTouchEndBound = this.onTouchEnd.bind(this)
    container.addEventListener('touchstart', this.onTouchStart, { passive: true })
    container.addEventListener('touchmove', this.onTouchMoveBound, { passive: false })
    container.addEventListener('touchend', this.onTouchEndBound, { passive: true })
    this.renderer.domElement.style.cursor = 'pointer'
    this.renderer.domElement.style.touchAction = 'none'
    window.addEventListener('resize', this.onResize)
  }

  private onTouchStart = (e: TouchEvent) => {
    this.touchStartX = e.touches[0].clientX
  }

  private onTouchMove = (e: TouchEvent) => {
    e.preventDefault()
    const delta = e.touches[0].clientX - this.touchStartX
    this.targetRotation += delta * 0.01
    this.touchStartX = e.touches[0].clientX
  }

  private onTouchEnd = (_e: TouchEvent) => {
    // Swipe completed, inertia will continue via existing animation loop
  }

  private onWheel = (e: WheelEvent) => {
    e.preventDefault()
    e.stopPropagation()
    this.targetRotation += e.deltaY * 0.005
  }

  private onClick = (e: MouseEvent) => {
    if (this.items.length === 0) return
    const rect = this.renderer.domElement.getBoundingClientRect()
    const mx = ((e.clientX - rect.left) / rect.width) * 2 - 1
    const my = -((e.clientY - rect.top) / rect.height) * 2 + 1

    const raycaster = new THREE.Raycaster()
    const mouse = new THREE.Vector2(mx, my)
    raycaster.setFromCamera(mouse, this.camera)

    const intersects = raycaster.intersectObjects(this.meshes)
    if (intersects.length > 0) {
      const hitMesh = intersects[0].object as THREE.Mesh
      const idx = this.meshes.indexOf(hitMesh)
      if (idx >= 0) {
        const item = this.items[idx]
        if (this.selectedId === item.id) {
          if (this.onSelectCallback) this.onSelectCallback(item)
        } else {
          this.selectedId = item.id
          this.paused = true
          this.highlightItem(idx)
        }
      }
    } else {
      this.selectedId = null
      this.paused = false
      this.clearHighlight()
    }
  }

  private highlightItem(idx: number) {
    this.meshes.forEach((mesh, i) => {
      const mat = mesh.material as THREE.ShaderMaterial
      if (i === idx) {
        mesh.scale.set(1.3, 1.3, 1.3)
        mat.uniforms.uBorderColor.value = new THREE.Color('#ffffff')
      } else {
        mesh.scale.set(1, 1, 1)
        mat.uniforms.uBorderColor.value = this.pColor
      }
    })
  }

  private clearHighlight() {
    this.meshes.forEach(mesh => {
      mesh.scale.set(1, 1, 1)
      const mat = mesh.material as THREE.ShaderMaterial
      mat.uniforms.uBorderColor.value = this.pColor
    })
  }

  onSelect(cb: (item: Gallery3DItem) => void) {
    this.onSelectCallback = cb
  }

  getSelectedId(): number | null { return this.selectedId }

  private onResize = () => {
    const w = window.innerWidth
    const h = window.innerHeight
    this.camera.aspect = w / h
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(w, h)
  }

  updateColors(primary: string, _accent: string) {
    const pColor = new THREE.Color(primary)
    this.group.children.forEach(child => {
      if (child instanceof THREE.Mesh) {
        const mat = child.material as THREE.ShaderMaterial
        mat.uniforms.uBorderColor.value = pColor
      }
      if (child instanceof THREE.LineSegments) {
        (child.material as THREE.LineBasicMaterial).color = pColor
      }
    })
  }

  getItemAtAngle(): Gallery3DItem | null {
    const yRot = this.group.rotation.y % (Math.PI * 2)
    const itemCount = this.items.length
    if (itemCount === 0) return null
    const closest = Math.round(yRot / (Math.PI * 2 / itemCount)) % itemCount
    const idx = ((closest % itemCount) + itemCount) % itemCount
    // The front-facing is at rotation 0, so offset
    const frontIdx = ((0 - idx) % itemCount + itemCount) % itemCount
    return this.items[frontIdx] || null
  }

  start() {
    const animate = () => {
      if (!this.paused) {
        this.rotationSpeed += (this.targetRotation - this.group.rotation.y) * 0.03
        this.rotationSpeed *= 0.92
        this.group.rotation.y += this.rotationSpeed
      }

      this.meshes.forEach(mesh => {
        const mat = mesh.material as THREE.ShaderMaterial
        mat.uniforms.uTime.value += 0.016
      })

      this.renderer.render(this.scene, this.camera)
      this.animationId = requestAnimationFrame(animate)
    }
    animate()
  }

  destroy() {
    cancelAnimationFrame(this.animationId)
    window.removeEventListener('resize', this.onResize)
    // Remove event listeners from container
    const container = this.renderer.domElement.parentElement
    if (container) {
      container.removeEventListener('wheel', this.onWheel)
      if (this.onClickBound) {
        container.removeEventListener('click', this.onClickBound)
      }
      if (this.onTouchMoveBound) {
        container.removeEventListener('touchmove', this.onTouchMoveBound)
        container.removeEventListener('touchend', this.onTouchEndBound!)
        container.removeEventListener('touchstart', this.onTouchStart)
      }
      if (this.renderer.domElement.parentNode === container) {
        container.removeChild(this.renderer.domElement)
      }
    }
    // 清理纹理
    this.textures.forEach(t => t.dispose())
    // 清理视频纹理和元素
    this.videoTextures.forEach(t => t.dispose())
    this.videoElements.forEach(video => {
      video.pause()
      video.src = ''
      video.remove()
    })
    this.renderer.dispose()
    this.group.clear()
    this.scene.clear()
  }
}
