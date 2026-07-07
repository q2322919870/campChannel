# Build Configuration and Vite Setup

<cite>
**Referenced Files in This Document**
- [vite.config.ts](file://camp-channel-client-pc/vite.config.ts)
- [tsconfig.json](file://camp-channel-client-pc/tsconfig.json)
- [tsconfig.node.json](file://camp-channel-client-pc/tsconfig.node.json)
- [package.json](file://camp-channel-client-pc/package.json)
- [main.ts](file://camp-channel-client-pc/src/main.ts)
- [App.vue](file://camp-channel-client-pc/src/App.vue)
- [env.d.ts](file://camp-channel-client-pc/src/env.d.ts)
- [router/index.ts](file://camp-channel-client-pc/src/router/index.ts)
- [stores/auth.ts](file://camp-channel-client-pc/src/stores/auth.ts)
- [stores/theme.ts](file://camp-channel-client-pc/src/stores/theme.ts)
- [vite.config.ts](file://camp-channel-client-uniapp/vite.config.ts)
- [package.json](file://camp-channel-client-uniapp/package.json)
- [tsconfig.json](file://camp-channel-client-uniapp/tsconfig.json)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)
10. [Appendices](#appendices)

## Introduction
This document explains the Vite build configuration and development setup for the PC web client and the UniApp client. It covers Vite configuration (plugins, server, proxy), TypeScript configuration and path aliases, the build pipeline, development server behavior, and integration with Vue Single File Components. It also provides guidance on production optimization, asset handling, and common build issues.

## Project Structure
Two distinct client projects are present:
- PC web client (Vue 3 + Vite): configured via vite.config.ts and TypeScript configs.
- UniApp client (Vue 3 + Vite via @dcloudio/vite-plugin-uni): configured via its own vite.config.ts and tsconfig.json.

Key files:
- PC Vite config defines the Vue plugin, path alias, and development server with API proxying.
- PC TypeScript configs define module resolution, bundler-aware settings, and path mapping.
- PC package.json scripts orchestrate dev/build/preview commands.
- UniApp Vite config uses the Uni plugin and a simpler proxy setup.
- UniApp TypeScript config defines paths and includes for Vue/TSX/Vue files.

```mermaid
graph TB
subgraph "PC Client"
PC_Vite["camp-channel-client-pc/vite.config.ts"]
PC_TS["camp-channel-client-pc/tsconfig.json"]
PC_TS_Node["camp-channel-client-pc/tsconfig.node.json"]
PC_Pkg["camp-channel-client-pc/package.json"]
PC_Main["camp-channel-client-pc/src/main.ts"]
PC_App["camp-channel-client-pc/src/App.vue"]
end
subgraph "UniApp Client"
UA_Vite["camp-channel-client-uniapp/vite.config.ts"]
UA_TS["camp-channel-client-uniapp/tsconfig.json"]
UA_Pkg["camp-channel-client-uniapp/package.json"]
end
PC_Vite --> PC_Main
PC_Main --> PC_App
PC_Vite --> PC_TS
PC_Vite --> PC_TS_Node
PC_Vite --> PC_Pkg
UA_Vite --> UA_Pkg
UA_Vite --> UA_TS
```

**Diagram sources**
- [vite.config.ts:1-35](file://camp-channel-client-pc/vite.config.ts#L1-L35)
- [tsconfig.json:1-25](file://camp-channel-client-pc/tsconfig.json#L1-L25)
- [tsconfig.node.json:1-11](file://camp-channel-client-pc/tsconfig.node.json#L1-L11)
- [package.json:1-28](file://camp-channel-client-pc/package.json#L1-L28)
- [main.ts:1-19](file://camp-channel-client-pc/src/main.ts#L1-L19)
- [App.vue:1-85](file://camp-channel-client-pc/src/App.vue#L1-L85)
- [vite.config.ts:1-16](file://camp-channel-client-uniapp/vite.config.ts#L1-L16)
- [tsconfig.json:1-28](file://camp-channel-client-uniapp/tsconfig.json#L1-L28)
- [package.json:1-29](file://camp-channel-client-uniapp/package.json#L1-L29)

**Section sources**
- [vite.config.ts:1-35](file://camp-channel-client-pc/vite.config.ts#L1-L35)
- [tsconfig.json:1-25](file://camp-channel-client-pc/tsconfig.json#L1-L25)
- [tsconfig.node.json:1-11](file://camp-channel-client-pc/tsconfig.node.json#L1-L11)
- [package.json:1-28](file://camp-channel-client-pc/package.json#L1-L28)
- [vite.config.ts:1-16](file://camp-channel-client-uniapp/vite.config.ts#L1-L16)
- [tsconfig.json:1-28](file://camp-channel-client-uniapp/tsconfig.json#L1-L28)
- [package.json:1-29](file://camp-channel-client-uniapp/package.json#L1-L29)

## Core Components
- Vite configuration (PC):
  - Plugin: Vue plugin enabled.
  - Path alias: @ resolves to src via fileURLToPath and URL.
  - Server: host binding, port, and proxy entries for API, uploads, and WebSocket.
  - Global define: sets global polyfill for compatibility.
- TypeScript configuration (PC):
  - Compiler options tuned for ESNext bundler resolution, DOM libraries, strictness, and path mapping.
  - References to tsconfig.node.json for Vite config consumption.
  - tsconfig.node.json enables bundler module resolution for Vite config.
- Scripts (PC):
  - dev: runs Vite dev server.
  - build: validates TS via vue-tsc then builds with Vite.
  - preview: serves built assets locally.
- UniApp configuration:
  - Uses @dcloudio/vite-plugin-uni.
  - Simplified proxy targeting the backend server.
  - Platform-specific dev/build scripts via uni CLI.

**Section sources**
- [vite.config.ts:5-35](file://camp-channel-client-pc/vite.config.ts#L5-L35)
- [tsconfig.json:2-24](file://camp-channel-client-pc/tsconfig.json#L2-L24)
- [tsconfig.node.json:2-10](file://camp-channel-client-pc/tsconfig.node.json#L2-L10)
- [package.json:5-9](file://camp-channel-client-pc/package.json#L5-L9)
- [vite.config.ts:4-15](file://camp-channel-client-uniapp/vite.config.ts#L4-L15)
- [package.json:5-10](file://camp-channel-client-uniapp/package.json#L5-L10)
- [tsconfig.json:2-27](file://camp-channel-client-uniapp/tsconfig.json#L2-L27)

## Architecture Overview
The development workflow connects the browser to Vite’s dev server, which proxies API and media requests to the backend. Vue components are compiled by Vite with the Vue plugin, while TypeScript is type-checked and transpiled per the compiler options.

```mermaid
graph TB
Browser["Browser"]
ViteDev["Vite Dev Server<br/>host: 0.0.0.0, port: 3000"]
ProxyAPI["Proxy /api -> http://localhost:8080"]
ProxyUploads["Proxy /uploads -> http://localhost:8080/api"]
ProxyWS["Proxy /ws -> http://localhost:8080/api (ws:true)"]
VueApp["Vue App<br/>main.ts -> App.vue"]
Backend["Backend Server :8080"]
Browser --> ViteDev
ViteDev --> ProxyAPI
ViteDev --> ProxyUploads
ViteDev --> ProxyWS
ProxyAPI --> Backend
ProxyUploads --> Backend
ProxyWS --> Backend
ViteDev --> VueApp
VueApp --> |"HTTP/WebSocket"| Backend
```

**Diagram sources**
- [vite.config.ts:16-34](file://camp-channel-client-pc/vite.config.ts#L16-L34)
- [main.ts:1-19](file://camp-channel-client-pc/src/main.ts#L1-L19)
- [App.vue:1-85](file://camp-channel-client-pc/src/App.vue#L1-L85)

## Detailed Component Analysis

### PC Vite Configuration
- Purpose: Enable Vue SFC support, configure path alias, expose global polyfill, and set up dev server with API proxying.
- Key elements:
  - define: global polyfill injection.
  - plugins: Vue plugin.
  - resolve.alias: @ mapped to src using import.meta URL helpers.
  - server.host/port/proxy: bind address, port, and proxy rules for API, uploads, and WebSocket.

```mermaid
flowchart TD
Start(["Load Vite Config"]) --> DefineGlobal["Set global polyfill"]
DefineGlobal --> Plugins["Enable Vue plugin"]
Plugins --> Alias["@ alias -> src"]
Alias --> Server["Configure dev server"]
Server --> HostPort["Host binding and port"]
HostPort --> ProxyRules["Define proxy rules"]
ProxyRules --> API["/api -> http://localhost:8080"]
ProxyRules --> Uploads["/uploads -> http://localhost:8080/api"]
ProxyRules --> WS["/ws -> http://localhost:8080/api (ws:true)"]
API --> End(["Ready"])
Uploads --> End
WS --> End
```

**Diagram sources**
- [vite.config.ts:5-35](file://camp-channel-client-pc/vite.config.ts#L5-L35)

**Section sources**
- [vite.config.ts:5-35](file://camp-channel-client-pc/vite.config.ts#L5-L35)

### TypeScript Configuration (PC)
- Compiler options:
  - Target/module/lib aligned with modern browsers and DOM APIs.
  - moduleResolution set to bundler for Vite compatibility.
  - allowImportingTsExtensions and resolveJsonModule enable modern module handling.
  - noEmit and isolatedModules ensure Vite handles transpilation.
  - paths map @/* to src/* for clean imports.
- References:
  - tsconfig.json references tsconfig.node.json for Vite config consumption.
  - tsconfig.node.json enables bundler module resolution for Vite config.

```mermaid
flowchart TD
TSRoot["tsconfig.json"] --> Options["Compiler options<br/>target/moduleResolution/paths"]
Options --> Bundler["moduleResolution=bundler"]
Options --> Paths["@/* -> src/*"]
Options --> Strict["strict/noUnused*"]
TSRoot --> References["references -> tsconfig.node.json"]
NodeTS["tsconfig.node.json"] --> NodeOpts["composite/bundler imports"]
```

**Diagram sources**
- [tsconfig.json:2-24](file://camp-channel-client-pc/tsconfig.json#L2-L24)
- [tsconfig.node.json:2-10](file://camp-channel-client-pc/tsconfig.node.json#L2-L10)

**Section sources**
- [tsconfig.json:2-24](file://camp-channel-client-pc/tsconfig.json#L2-L24)
- [tsconfig.node.json:2-10](file://camp-channel-client-pc/tsconfig.node.json#L2-L10)

### Build Pipeline and Scripts (PC)
- Scripts:
  - dev: starts Vite dev server.
  - build: runs vue-tsc for type-checking, then vite build for production bundles.
  - preview: serves the production build locally.
- Implications:
  - Type-checking precedes bundling to catch errors early.
  - Vite handles asset optimization and code splitting in production.

```mermaid
sequenceDiagram
participant Dev as "Developer"
participant NPM as "npm scripts"
participant TSC as "vue-tsc"
participant Vite as "Vite build"
Dev->>NPM : npm run build
NPM->>TSC : type-check project
TSC-->>NPM : type-check OK
NPM->>Vite : vite build
Vite-->>Dev : dist/ ready
```

**Diagram sources**
- [package.json:5-9](file://camp-channel-client-pc/package.json#L5-L9)

**Section sources**
- [package.json:5-9](file://camp-channel-client-pc/package.json#L5-L9)

### Development Server, HMR, and Proxy (PC)
- HMR: Enabled by default in Vite dev server; Vue SFC updates propagate without full reload.
- Proxy:
  - /api forwards REST calls to backend.
  - /uploads forwards static/media to backend API endpoint.
  - /ws forwards WebSocket traffic for real-time features.
- Network accessibility:
  - server.host binds to 0.0.0.0 to allow LAN access.

```mermaid
sequenceDiagram
participant Browser as "Browser"
participant Vite as "Vite Dev Server"
participant Proxy as "Proxy Layer"
participant Backend as "Backend : 8080"
Browser->>Vite : GET /api/...
Vite->>Proxy : forward
Proxy->>Backend : HTTP request
Backend-->>Proxy : response
Proxy-->>Vite : response
Vite-->>Browser : proxied response
Browser->>Vite : WebSocket /ws/...
Vite->>Proxy : upgrade
Proxy->>Backend : upgrade
Backend-->>Proxy : ws connected
Proxy-->>Vite : ws connected
Vite-->>Browser : ws connected
```

**Diagram sources**
- [vite.config.ts:16-34](file://camp-channel-client-pc/vite.config.ts#L16-L34)

**Section sources**
- [vite.config.ts:16-34](file://camp-channel-client-pc/vite.config.ts#L16-L34)

### Integration with Vue Single File Components (PC)
- Entry point initializes Vue app, Pinia, and router, then mounts to #app.
- App.vue conditionally renders layout vs auth views and applies theme/store logic.
- Router lazy-loads pages to enable code splitting and route-level chunks.
- Stores encapsulate auth and theme state with persistence.

```mermaid
sequenceDiagram
participant Main as "main.ts"
participant App as "App.vue"
participant Router as "router/index.ts"
participant StoreAuth as "stores/auth.ts"
participant StoreTheme as "stores/theme.ts"
Main->>Main : createApp(App)
Main->>Main : app.use(Pinia, Router)
Main->>App : mount("#app")
App->>StoreAuth : loadFromStorage()
App->>StoreTheme : applyTheme()
Router->>Router : beforeEach guards
Router-->>App : route changes trigger SFC updates
```

**Diagram sources**
- [main.ts:1-19](file://camp-channel-client-pc/src/main.ts#L1-L19)
- [App.vue:1-85](file://camp-channel-client-pc/src/App.vue#L1-L85)
- [router/index.ts:1-46](file://camp-channel-client-pc/src/router/index.ts#L1-L46)
- [stores/auth.ts:1-61](file://camp-channel-client-pc/src/stores/auth.ts#L1-L61)
- [stores/theme.ts:1-295](file://camp-channel-client-pc/src/stores/theme.ts#L1-L295)

**Section sources**
- [main.ts:1-19](file://camp-channel-client-pc/src/main.ts#L1-L19)
- [App.vue:1-85](file://camp-channel-client-pc/src/App.vue#L1-L85)
- [router/index.ts:1-46](file://camp-channel-client-pc/src/router/index.ts#L1-L46)
- [stores/auth.ts:1-61](file://camp-channel-client-pc/src/stores/auth.ts#L1-L61)
- [stores/theme.ts:1-295](file://camp-channel-client-pc/src/stores/theme.ts#L1-L295)

### UniApp Vite Configuration
- Plugin: @dcloudio/vite-plugin-uni.
- Server: port and simplified proxy for /api to backend.
- Scripts: platform-specific dev/build via uni CLI.

```mermaid
flowchart TD
UA_Vite["UniApp vite.config.ts"] --> UA_Plugin["@dcloudio/vite-plugin-uni"]
UA_Vite --> UA_Server["port + /api proxy"]
UA_Scripts["uni scripts"] --> UA_Platform["mp-weixin / h5"]
```

**Diagram sources**
- [vite.config.ts:1-16](file://camp-channel-client-uniapp/vite.config.ts#L1-L16)
- [package.json:5-10](file://camp-channel-client-uniapp/package.json#L5-L10)

**Section sources**
- [vite.config.ts:1-16](file://camp-channel-client-uniapp/vite.config.ts#L1-L16)
- [package.json:5-10](file://camp-channel-client-uniapp/package.json#L5-L10)
- [tsconfig.json:1-28](file://camp-channel-client-uniapp/tsconfig.json#L1-L28)

## Dependency Analysis
- PC client dependencies:
  - Vue 3 runtime and ecosystem (router, pinia).
  - Vite and @vitejs/plugin-vue for dev/build.
  - TypeScript toolchain and vue-tsc for type checking.
  - axios and STOMP/SockJS for HTTP/WebSocket communication.
- UniApp client dependencies:
  - @dcloudio/uni-app and related packages for cross-platform runtime.
  - @dcloudio/vite-plugin-uni and Vite for build.
  - TypeScript and Vite for type checking and bundling.

```mermaid
graph LR
PC_Vue["vue@^3.x"] --- PC_Router["vue-router@^4.x"]
PC_Vue --- PC_Pinia["pinia@^2.x"]
PC_Vite["vite@^5.x"] --- PC_PluginVue["@vitejs/plugin-vue@^5.x"]
PC_TSC["typescript@^5.x"] --- PC_VueTSC["vue-tsc@^2.x"]
PC_Axios["axios@^1.x"] --- PC_WS["sockjs-client@^1.x / @stomp/stompjs@^7.x"]
UA_Uni["@dcloudio/uni-app@3.x"] --- UA_Plugin["@dcloudio/vite-plugin-uni@3.x"]
UA_Types["typescript@^5.x"] --- UA_Vite["vite@^5.x"]
```

**Diagram sources**
- [package.json:10-26](file://camp-channel-client-pc/package.json#L10-L26)
- [package.json:11-27](file://camp-channel-client-uniapp/package.json#L11-L27)

**Section sources**
- [package.json:10-26](file://camp-channel-client-pc/package.json#L10-L26)
- [package.json:11-27](file://camp-channel-client-uniapp/package.json#L11-L27)

## Performance Considerations
- Code splitting:
  - Lazy-loaded route components reduce initial bundle size.
- Asset handling:
  - Vite optimizes static assets; ensure media paths match proxy endpoints (/uploads).
- Module resolution:
  - bundler moduleResolution reduces overhead and improves compatibility.
- Strictness and checks:
  - strict TypeScript settings catch potential runtime issues early.
- Production build:
  - Use vite build with vue-tsc precheck to validate types before bundling.

[No sources needed since this section provides general guidance]

## Troubleshooting Guide
- Proxy does not forward requests:
  - Verify server.host and port match the dev server configuration.
  - Confirm proxy entries for /api, /uploads, and /ws are present.
- WebSocket connection fails:
  - Ensure ws: true is set for /ws proxy.
  - Check backend WebSocket endpoint availability.
- Path alias not resolved:
  - Confirm @ alias maps to src in both Vite and TypeScript configs.
- Type errors during build:
  - Run vue-tsc separately to identify TS issues before vite build.
- CORS or origin mismatch:
  - changeOrigin is enabled; ensure backend allows origins from dev server host/port.

**Section sources**
- [vite.config.ts:16-34](file://camp-channel-client-pc/vite.config.ts#L16-L34)
- [tsconfig.json:18-20](file://camp-channel-client-pc/tsconfig.json#L18-L20)
- [package.json:7-8](file://camp-channel-client-pc/package.json#L7-L8)

## Conclusion
The PC client leverages Vite with a Vue plugin, robust path aliasing, and a development server configured with API, uploads, and WebSocket proxies. TypeScript is configured for modern bundler behavior and strictness, while scripts orchestrate type-checking and production builds. The UniApp client integrates with @dcloudio/vite-plugin-uni and uses a streamlined proxy setup. Together, these configurations enable efficient development and reliable production builds.

## Appendices
- Example references to configuration files:
  - PC Vite config: [vite.config.ts:1-35](file://camp-channel-client-pc/vite.config.ts#L1-L35)
  - PC TypeScript root: [tsconfig.json:1-25](file://camp-channel-client-pc/tsconfig.json#L1-L25)
  - PC TypeScript node: [tsconfig.node.json:1-11](file://camp-channel-client-pc/tsconfig.node.json#L1-L11)
  - PC scripts: [package.json:5-9](file://camp-channel-client-pc/package.json#L5-L9)
  - UniApp Vite config: [vite.config.ts:1-16](file://camp-channel-client-uniapp/vite.config.ts#L1-L16)
  - UniApp scripts: [package.json:5-10](file://camp-channel-client-uniapp/package.json#L5-L10)
  - UniApp TypeScript: [tsconfig.json:1-28](file://camp-channel-client-uniapp/tsconfig.json#L1-L28)