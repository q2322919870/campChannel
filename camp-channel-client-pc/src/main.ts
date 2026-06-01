import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './style.css'
import { initCursorEffects } from './utils/cursorRenderer'
import { initHybridTransitions } from './utils/hybridTransitionManager'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')

// Initialize cursor effects after app mounts
initCursorEffects()

// Initialize hybrid (CSS + Canvas) page transitions
initHybridTransitions()
