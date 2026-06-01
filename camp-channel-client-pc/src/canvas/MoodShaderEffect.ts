import * as THREE from 'three'

export interface MoodColors {
  primary: string
  accent: string
  glowColor: string
}

export class MoodShaderEffect {
  private scene: THREE.Scene
  private camera: THREE.OrthographicCamera
  private renderer: THREE.WebGLRenderer
  private material: THREE.ShaderMaterial
  private animId = 0
  private startTime = 0
  private running = false

  constructor(container: HTMLElement, colors: MoodColors) {
    this.renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true })
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2))
    this.renderer.setSize(container.clientWidth, container.clientHeight)
    this.renderer.domElement.style.pointerEvents = 'none'
    this.renderer.domElement.style.position = 'absolute'
    this.renderer.domElement.style.inset = '0'
    this.renderer.domElement.style.zIndex = '0'
    this.renderer.domElement.style.borderRadius = 'inherit'
    container.style.position = 'relative'
    container.prepend(this.renderer.domElement)

    this.scene = new THREE.Scene()
    this.camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1)

    this.material = new THREE.ShaderMaterial({
      transparent: true,
      uniforms: {
        uTime: { value: 0 },
        uColor1: { value: this.hexToVec3(colors.primary) },
        uColor2: { value: this.hexToVec3(colors.accent) },
        uGlow: { value: this.hexToVec3(colors.glowColor) },
        uIntensity: { value: 0.3 },
        uMode: { value: 0 },
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
        uniform vec3 uColor1;
        uniform vec3 uColor2;
        uniform vec3 uGlow;
        uniform float uIntensity;
        uniform float uMode;

        // Simplex-like noise
        float noise(vec2 p) {
          return sin(p.x * 12.9898 + p.y * 78.233) * 43758.5453;
        }

        void main() {
          vec2 uv = vUv;
          float t = uTime;

          if (uMode < 0.5) {
            // Breathing glass effect
            float breathe = sin(t * 1.5) * 0.15 + 0.15;
            float dist = length(uv - 0.5);
            float ripple = sin(dist * 10.0 - t * 2.0) * 0.05;
            float wave = sin(uv.x * 8.0 + t) * cos(uv.y * 6.0 + t * 0.7) * 0.08;
            float alpha = (breathe + ripple + wave) * uIntensity;
            vec3 col = mix(uColor1, uColor2, sin(t * 0.5 + uv.x * 2.0) * 0.3 + 0.5);
            col += uGlow * (breathe * 0.5);
            gl_FragColor = vec4(col, alpha * 0.4);
          } else {
            // Glitch effect
            float glitch = step(0.97, sin(uv.y * 100.0 + t * 5.0));
            float shift = sin(uv.y * 50.0 + t * 3.0) * 0.02 * glitch;
            vec2 gUv = vec2(uv.x + shift, uv.y);
            float flicker = step(0.995, sin(t * 20.0 + uv.y * 200.0));
            float bar = step(0.02, abs(sin(uv.y * 50.0 + t * 4.0)));
            vec3 col = mix(uColor1, uColor2, gUv.y);
            col = mix(col, uGlow, flicker * 0.3);
            col = mix(col, vec3(0.0), (1.0 - bar) * glitch * 0.5);
            gl_FragColor = vec4(col, 0.2 + glitch * 0.15);
          }
        }
      `,
    })

    const geo = new THREE.PlaneGeometry(2, 2)
    const mesh = new THREE.Mesh(geo, this.material)
    this.scene.add(mesh)
  }

  setMode(mode: 'glass' | 'glitch') {
    this.material.uniforms.uMode.value = mode === 'glass' ? 0 : 1
  }

  setIntensity(v: number) {
    this.material.uniforms.uIntensity.value = v
  }

  updateColors(colors: MoodColors) {
    this.material.uniforms.uColor1.value = this.hexToVec3(colors.primary)
    this.material.uniforms.uColor2.value = this.hexToVec3(colors.accent)
    this.material.uniforms.uGlow.value = this.hexToVec3(colors.glowColor)
  }

  start() {
    if (this.running) return
    this.running = true
    this.startTime = performance.now()
    const animate = () => {
      if (!this.running) return
      this.material.uniforms.uTime.value = (performance.now() - this.startTime) / 1000
      this.renderer.render(this.scene, this.camera)
      this.animId = requestAnimationFrame(animate)
    }
    animate()
  }

  stop() {
    this.running = false
    cancelAnimationFrame(this.animId)
  }

  destroy() {
    this.stop()
    this.renderer.dispose()
    this.scene.clear()
    this.renderer.domElement.remove()
  }

  private hexToVec3(hex: string): THREE.Vector3 {
    const r = parseInt(hex.slice(1, 3), 16) / 255
    const g = parseInt(hex.slice(3, 5), 16) / 255
    const b = parseInt(hex.slice(5, 7), 16) / 255
    return new THREE.Vector3(r, g, b)
  }
}
