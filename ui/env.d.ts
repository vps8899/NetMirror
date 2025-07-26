/// <reference types="vite/client" />

declare module "*.vue" {
  import type { DefineComponent } from "vue"
  const component: DefineComponent<{}, {}, any>
  export default component
}

declare module "vue3-apexcharts" {
  import type { DefineComponent } from "vue"
  const VueApexCharts: DefineComponent<any, any, any>
  export default VueApexCharts
}

declare module "vue3-markdown-it" {
  import type { DefineComponent } from "vue"
  const Markdown: DefineComponent<any, any, any>
  export default Markdown
}

declare module "v-clipboard" {
  import type { App } from "vue"
  const plugin: {
    install(app: App): void
  }
  export default plugin
}

interface ImportMetaEnv {
  readonly VITE_APP_TITLE: string
  readonly VITE_APP_VERSION: string
  readonly VITE_API_BASE_URL: string
  readonly VITE_WS_BASE_URL: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

// Global constants injected by Vite
declare const __APP_VERSION__: string
declare const __BUILD_TIME__: string
