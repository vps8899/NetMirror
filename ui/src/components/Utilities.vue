<script setup>
import { ref, computed, defineAsyncComponent, onMounted, h, shallowRef, toRaw } from 'vue'
import { storeToRefs } from 'pinia'
import { useAppStore } from '@/stores/app'
import { useNodeTool } from '@/composables/useNodeTool'

const appStore = useAppStore()
const {
  selectedNode,
} = useNodeTool()

const config = computed(() => {
  if (selectedNode.value && selectedNode.value.config) {
    return selectedNode.value.config
  }
  return appStore.config
})

const toolComponent = shallowRef(null)
const currentTool = ref(null)

const toolComponentShow = computed({
  get() {
    return currentTool.value !== null
  },
  set(newValue) {
    if (!newValue) {
      currentTool.value = null
      toolComponent.value = null
    }
  }
})

const tools = ref([
  {
    id: 'ping',
    label: 'Ping',
    description: 'IPv4 connectivity test',
    color: 'from-primary-500 to-primary-600',
    featureFlag: 'feature_ping',
    icon: 'M13 10V3L4 14h7v7l9-11h-7z',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Ping.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'ping6',
    label: 'Ping IPv6',
    description: 'IPv6 connectivity test',
    color: 'from-primary-600 to-blue-600',
    featureFlag: 'feature_ping',
    icon: 'M13 10V3L4 14h7v7l9-11h-7z',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Ping6.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'mtr',
    label: 'MTR',
    description: 'Network path analysis',
    color: 'from-blue-500 to-sky-500',
    featureFlag: 'feature_mtr',
    icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/MTR.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'mtr6',
    label: 'MTR IPv6',
    description: 'IPv6 path analysis',
    color: 'from-sky-500 to-cyan-500',
    featureFlag: 'feature_mtr',
    icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/MTR6.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'traceroute',
    label: 'Traceroute',
    description: 'Route path discovery',
    color: 'from-purple-500 to-pink-500',
    featureFlag: 'feature_traceroute',
    icon: 'M13 7h8m0 0v8m0-8l-8 8-4-4-6 6',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Traceroute.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'traceroute6',
    label: 'Traceroute IPv6',
    description: 'IPv6 route discovery',
    color: 'from-pink-500 to-rose-500',
    featureFlag: 'feature_traceroute',
    icon: 'M13 7h8m0 0v8m0-8l-8 8-4-4-6 6',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Traceroute6.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'iperf3',
    label: 'IPerf3',
    description: 'Bandwidth measurement',
    color: 'from-green-500 to-emerald-500',
    featureFlag: 'feature_iperf3',
    icon: 'M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/IPerf3.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'speedtest-net',
    label: 'Speedtest.net',
    description: 'Official Speedtest CLI',
    color: 'from-orange-500 to-amber-500',
    featureFlag: 'feature_speedtest_dot_net',
    icon: 'M13 10V3L4 14h7v7l9-11h-7z',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/SpeedtestNet.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  },
  {
    id: 'shell',
    label: 'Shell',
    description: 'Interactive command line',
    color: 'from-gray-600 to-gray-700',
    featureFlag: 'feature_shell',
    icon: 'M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z',
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Shell.vue'),
      delay: 200,
      timeout: 10000,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ]),
      errorComponent: () => h('div', { class: 'text-red-500 p-4' }, 'Failed to load component')
    })
  }
])

// 过滤可用的工具
const availableTools = computed(() => {
  return tools.value.filter(tool => {
    return config.value && config.value[tool.featureFlag]
  })
})

const loadComponentOnDemand = (tool) => {
  if (!toolComponent.value || toolComponent.value !== tool.componentNode) {
    toolComponent.value = tool.componentNode
  }
}

const openTool = (tool) => {
  currentTool.value = tool
  // Only load component when actually needed
  loadComponentOnDemand(tool)
}

const closeTool = () => {
  toolComponentShow.value = false
}
</script>

<template>
  <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden animate-slide-up" style="animation-delay: 0.1s;">
    <div class="p-4 md:p-6">
      <!-- Mobile: Header with description -->
      <div class="mb-4 md:mb-6">
        <h2 class="text-lg md:text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">Network Diagnostic Tools</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400">Choose from available network testing and diagnostic utilities</p>
      </div>
      
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 md:gap-4">
        <!-- 动态渲染工具卡片 - 优化移动端 -->
        <button
          v-for="tool in availableTools"
          :key="tool.id"
          @click="openTool(tool)"
          class="group relative overflow-hidden rounded-xl p-4 md:p-5 text-left bg-primary-50/30 dark:bg-gray-700/30 border border-primary-200/50 dark:border-gray-600/50 hover:border-transparent transition-all duration-300 transform hover:scale-[1.02] active:scale-[0.98] min-h-[120px] md:min-h-[auto]"
        >
          <!-- 渐变边框效果 -->
          <div class="absolute -inset-px rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 bg-gradient-to-br" :class="tool.color"></div>
          
          <!-- 卡片内容 - 移动端垂直布局，桌面端水平布局 -->
          <div class="relative z-10 flex flex-col sm:flex-row sm:items-center space-y-3 sm:space-y-0 sm:space-x-4 h-full">
            <!-- 图标 -->
            <div class="flex items-center justify-center w-12 h-12 mx-auto sm:mx-0 rounded-xl bg-gradient-to-br group-hover:bg-white/20 group-hover:scale-110 transition-all duration-300 group-hover:rotate-12 flex-shrink-0" :class="tool.color">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="tool.icon"></path>
              </svg>
            </div>
            
            <!-- 文字内容 -->
            <div class="text-center sm:text-left flex-1">
              <h3 class="text-base md:text-lg font-semibold text-gray-900 dark:text-gray-100 group-hover:text-white transition-colors duration-300 mb-1">{{ tool.label }}</h3>
              <p class="text-xs md:text-sm text-gray-600 dark:text-gray-300 group-hover:text-white/80 transition-colors duration-300 line-clamp-2">{{ tool.description }}</p>
            </div>
          </div>
          
          <!-- 底部进度条 -->
          <div class="absolute inset-x-0 bottom-0 h-0.5 bg-gradient-to-r transform scale-x-0 group-hover:scale-x-100 transition-transform duration-300" :class="tool.color"></div>
        </button>
      </div>
    </div>
  </div>

  <!-- Tool Drawer -->
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-300"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition-opacity duration-300"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div v-if="toolComponentShow" class="fixed inset-0 z-50 overflow-hidden">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black/30 backdrop-blur-sm" @click="closeTool"></div>
        
        <!-- Drawer -->
        <Transition
          enter-active-class="transition-transform duration-500 ease-[cubic-bezier(0.16,1,0.3,1)]"
          enter-from-class="translate-x-full"
          enter-to-class="translate-x-0"
          leave-active-class="transition-transform duration-300 ease-in-out"
          leave-from-class="translate-x-0"
          leave-to-class="translate-x-full"
        >
          <div v-if="toolComponentShow" class="absolute right-0 top-0 h-full w-full max-w-3xl bg-white/95 dark:bg-gray-900/95 backdrop-blur-lg shadow-2xl flex flex-col border-l border-primary-200/50 dark:border-primary-700/50">
            <!-- Header -->
            <div class="flex items-center justify-between p-4 border-b border-primary-200/30 dark:border-primary-700/30 flex-shrink-0 bg-primary-50/50 dark:bg-gray-800/50">
              <div class="flex items-center space-x-4">
                <div v-if="currentTool" class="flex items-center justify-center w-10 h-10 rounded-xl" :class="`bg-gradient-to-br ${currentTool.color}`">
                  <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                  </svg>
                </div>
                <div>
                  <h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">{{ currentTool?.label }}</h2>
                  <p class="text-sm text-gray-600 dark:text-gray-300">{{ currentTool?.description }}</p>
                </div>
              </div>
              <button
                @click="closeTool"
                class="flex items-center justify-center w-10 h-10 rounded-full bg-primary-100 hover:bg-primary-200 dark:bg-gray-700 dark:hover:bg-gray-600 transition-colors duration-200"
              >
                <svg class="w-5 h-5 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
            
            <!-- Content -->
            <div class="flex-1 overflow-y-auto p-6 bg-primary-25 dark:bg-gray-850">
              <component :is="toolComponent" @closed="closeTool" />
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.animate-slide-up {
  animation: slideUp 0.4s ease-out;
}

@keyframes slideUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}
</style>
