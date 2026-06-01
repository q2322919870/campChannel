import * as THREE from 'three'

export interface FluidColors {
  primary: string
  secondary: string
  glowColor: string
}

export class FluidBackground {
  private scene: THREE.Scene
  private camera: THREE.OrthographicCamera
  private renderer: THREE.WebGLRenderer
  private material: THREE.ShaderMaterial
  private mouse = { x: 0.5, y: 0.5 }
  private time = 0
  private animationId = 0

  constructor(colors: FluidColors) {
    this.scene = new THREE.Scene()
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1)

    this.renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.renderer.setSize(window.innerWidth, window.innerHeight)

    const c1 = this.hexToVec3(colors.primary)
    const c2 = this.hexToVec3(colors.secondary)
    const c3 = this.hexToVec3(colors.glowColor)

    this.material = new THREE.ShaderMaterial({
      uniforms: {
        uTime: { value: 0 },
        uMouse: { value: new THREE.Vector2(0.5, 0.5) },
        uRes: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
        uColor1: { value: c1 },
        uColor2: { value: c2 },
        uColor3: { value: c3 },
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
        uniform float uTime;
        uniform vec2 uMouse;
        uniform vec2 uRes;
        uniform vec3 uColor1;
        uniform vec3 uColor2;
        uniform vec3 uColor3;

        void main() {
          vec2 uv = vUv;
          float aspect = uRes.x / uRes.y;

          vec2 p = (uv - 0.5) * vec2(aspect, 1.0);

          float t = uTime * 0.15;

          // Fluid-like flow using sine waves
          float d1 = sin(p.x * 3.0 + t) * cos(p.y * 3.0 + t * 0.7);
          float d2 = sin(p.x * 5.0 - t * 0.9 + 1.2) * cos(p.y * 4.0 + t * 0.5 + 2.1);
          float d3 = sin((p.x + p.y) * 6.0 + t * 0.3) * 0.5 + 0.5;

          // Mouse influence
          float mx = (uMouse.x - 0.5) * aspect;
          float my = uMouse.y - 0.5;
          float md = 1.0 - smoothstep(0.0, 0.8, length(p - vec2(mx, my)));

          // Voronoi-like pattern
          float n = sin(p.x * 8.0 + p.y * 6.0 + t) * 0.3
                  + cos(p.x * 12.0 - p.y * 10.0 + t * 1.3) * 0.2;

          float blend = (d1 * 0.5 + d2 * 0.3 + d3 * 0.2 + n + md * 0.15);

          vec3 col = mix(uColor1, uColor2, smoothstep(-0.8, 0.8, blend));
          col = mix(col, uColor3, smoothstep(0.3, 1.0, d2) * 0.3);

          // Pulse glow
          float pulse = sin(t * 2.0) * 0.1 + 0.1;
          col += uColor3 * (pulse * 0.15 + md * 0.08);

          // Vignette
          float vig = 1.0 - length(uv - 0.5) * 0.6;
          col *= vig;

          gl_FragColor = vec4(col, 0.6);
        }
      `,
    })

    const geo = new THREE.PlaneGeometry(2, 2)
    const mesh = new THREE.Mesh(geo, this.material)
    this.scene.add(mesh)

    window.addEventListener('resize', this.onResize)
    window.addEventListener('mousemove', this.onMouseMove)
  }

  getCanvas(): HTMLCanvasElement {
    return this.renderer.domElement
  }

  private hexToVec3(hex: string): THREE.Vector3 {
    const r = parseInt(hex.slice(1, 3), 16) / 255
    const g = parseInt(hex.slice(3, 5), 16) / 255
    const b = parseInt(hex.slice(5, 7), 16) / 255
    return new THREE.Vector3(r, g, b)
  }

  updateColors(colors: FluidColors) {
    this.material.uniforms.uColor1.value = this.hexToVec3(colors.primary)
    this.material.uniforms.uColor2.value = this.hexToVec3(colors.secondary)
    this.material.uniforms.uColor3.value = this.hexToVec3(colors.glowColor)
  }

  private onResize = () => {
    this.renderer.setSize(window.innerWidth, window.innerHeight)
    this.material.uniforms.uRes.value.set(window.innerWidth, window.innerHeight)
  }

  private onMouseMove = (e: MouseEvent) => {
    this.mouse.x = e.clientX / window.innerWidth
    this.mouse.y = 1 - e.clientY / window.innerHeight
  }

  start() {
    const animate = () => {
      this.time += 0.016
      this.material.uniforms.uTime.value = this.time
      this.material.uniforms.uMouse.value.set(this.mouse.x, this.mouse.y)
      this.renderer.render(this.scene, this.camera)
      this.animationId = requestAnimationFrame(animate)
    }
    animate()
  }

  destroy() {
    cancelAnimationFrame(this.animationId)
    window.removeEventListener('resize', this.onResize)
    window.removeEventListener('mousemove', this.onMouseMove)
    this.renderer.dispose()
    this.scene.clear()
  }
}
