<script setup>
import { ref, computed, defineAsyncComponent, onMounted, h, shallowRef, toRaw } from 'vue'
import { storeToRefs } from 'pinia'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const { config } = storeToRefs(appStore)

const toolComponent = shallowRef(null)
const currentTool = ref(null)
const targetHost = ref('')
const selectedMethod = ref('ping')
const isExecuting = ref(false)
const output = ref('')
const showOutput = ref(false)

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

const hasToolEnable = computed(() => {
  return tools.value.some(tool => tool.enable)
})

const availableMethods = computed(() => {
  const methods = []
  if (config.value.feature_ping) {
    methods.push(
      { value: 'ping', label: 'ping' },
      { value: 'ping6', label: 'ping6' }
    )
  }
  if (config.value.feature_mtr) {
    methods.push(
      { value: 'mtr', label: 'mtr' },
      { value: 'mtr6', label: 'mtr6' }
    )
  }
  if (config.value.feature_traceroute) {
    methods.push(
      { value: 'traceroute', label: 'traceroute' },
      { value: 'traceroute6', label: 'traceroute6' }
    )
  }
  return methods
})

const tools = ref([
  {
    label: 'Ping',
    description: 'Test network connectivity',
    color: 'from-primary-500 to-primary-600',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Ping.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  },
  {
    label: 'IPerf3',
    description: 'Measure network bandwidth',
    color: 'from-primary-600 to-blue-600',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/IPerf3.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  },
  {
    label: 'Speedtest.net',
    description: 'Official Speedtest CLI',
    color: 'from-blue-500 to-sky-500',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/SpeedtestNet.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  },
  {
    label: 'Shell',
    description: 'Interactive command line',
    color: 'from-gray-600 to-gray-700',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Shell.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  }
])

onMounted(() => {
  for (const tool of tools.value) {
    const configKey = 'feature_' + tool.label.toLowerCase().replace('.', '_dot_')
    tool.enable = config.value[configKey] ?? false
  }
  
  // Set default method
  if (availableMethods.value.length > 0) {
    selectedMethod.value = availableMethods.value[0].value
  }
})

const openTool = (tool) => {
  currentTool.value = tool
  toolComponent.value = toRaw(tool.componentNode)
}

const closeTool = () => {
  toolComponentShow.value = false
}

const executeTest = async () => {
  if (!targetHost.value.trim()) return
  
  isExecuting.value = true
  showOutput.value = true
  output.value = `Executing ${selectedMethod.value} to ${targetHost.value}...\n`
  
  try {
    // 创建一个 AbortController 来控制请求取消
    const controller = new AbortController()
    
    // 调用后端API
    const response = await appStore.requestMethod(selectedMethod.value, {
      ip: targetHost.value.trim()
    }, controller.signal)
    
    if (response.success) {
      // 清空之前的占位符输出
      output.value = ''
      
      // 如果有实时输出，通过SSE接收
      if (response.data && response.data.output) {
        output.value = response.data.output
      } else {
        // 根据不同的方法监听不同的事件
        const eventName = selectedMethod.value === 'ping' ? 'Ping' : 'MethodOutput'
        
        const handleOutput = (event) => {
          if (selectedMethod.value === 'ping') {
            // ping事件返回的是ping包数据，需要解析
            const data = JSON.parse(event.data)
            console.log('Ping event data:', data) // 调试日志
            
            if (data.from && data.latency !== undefined) {
              const latencyMs = (data.latency / 1e6).toFixed(2) // 纳秒转毫秒
              output.value += `64 bytes from ${data.from}: icmp_seq=${data.seq} ttl=${data.ttl} time=${latencyMs} ms\n`
            }
            
            // 检查是否超时
            if (data.is_timeout) {
              output.value += `Request timeout for icmp_seq ${data.seq}\n`
            }
            
            // ping完成10次后自动停止
            if (data.seq >= 9) { // seq从0开始，所以9表示第10个包
              setTimeout(() => {
                appStore.source.removeEventListener(eventName, handleOutput)
                isExecuting.value = false
                output.value += '\n--- ping statistics ---\n'
                output.value += 'Ping completed.\n'
              }, 1000)
            }
          } else {
            // nettools事件返回的是带output字段的数据
            const data = JSON.parse(event.data)
            if (data.output) {
              output.value += data.output
            }
            if (data.finished) {
              appStore.source.removeEventListener(eventName, handleOutput)
              isExecuting.value = false
            }
          }
        }
        
        appStore.source.addEventListener(eventName, handleOutput)
        
        // 设置超时保护
        setTimeout(() => {
          appStore.source.removeEventListener(eventName, handleOutput)
          if (isExecuting.value) {
            output.value += '\nTest timed out after 60 seconds.\n'
            isExecuting.value = false
          }
        }, 60000)
      }
    } else {
      output.value += `Error: ${response.message || 'Unknown error occurred'}\n`
      isExecuting.value = false
    }
    
  } catch (error) {
    if (error.name === 'AbortError') {
      output.value += '\nTest was cancelled.\n'
    } else {
      output.value += `Error: ${error.message || 'Network error occurred'}\n`
    }
    isExecuting.value = false
  }
}
</script>

<template>
  <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden animate-slide-up" style="animation-delay: 0.1s;">
    <div class="bg-gradient-to-r from-primary-600 to-primary-700 px-6 py-4">
      <h2 class="text-xl font-semibold text-white flex items-center">
        <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"></path>
        </svg>
        Looking Glass
      </h2>
    </div>
    <div class="p-6">
      <div class="space-y-6">
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div class="lg:col-span-2">
            <label class="block text-sm font-medium text-gray-600 dark:text-gray-300 mb-2">Target Host or IP Address</label>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9"></path>
                </svg>
              </div>
              <input 
                v-model="targetHost"
                type="text" 
                class="w-full pl-10 pr-4 py-3 bg-primary-50/50 dark:bg-gray-700 border border-primary-200 dark:border-gray-600 rounded-lg text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-all duration-200" 
                placeholder="Enter IP address or hostname..." 
                required
              >
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-600 dark:text-gray-300 mb-2">Test Method</label>
            <div class="relative">
              <select 
                v-model="selectedMethod"
                class="w-full appearance-none bg-primary-50/50 dark:bg-gray-700 border border-primary-200 dark:border-gray-600 rounded-lg px-4 py-3 pr-10 text-slate-700 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-all duration-200"
              >
                <option v-for="method in availableMethods" :key="method.value" :value="method.value">
                  {{ method.label }}
                </option>
              </select>
              <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                </svg>
              </div>
            </div>
          </div>
        </div>

        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between space-y-4 sm:space-y-0">
          <button 
            @click="executeTest"
            :disabled="isExecuting || !targetHost.trim()"
            class="inline-flex items-center px-6 py-3 bg-primary-600 hover:bg-primary-700 disabled:bg-gray-400 text-white font-medium rounded-lg shadow-md hover:shadow-lg transform hover:-translate-y-0.5 transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:transform-none disabled:cursor-not-allowed"
          >
            <svg v-if="!isExecuting" class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
            </svg>
            <svg v-else class="w-5 h-5 mr-2 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
            </svg>
            {{ isExecuting ? 'Executing...' : 'Execute Test' }}
          </button>
        </div>

        <!-- Output Terminal -->
        <div v-if="showOutput" class="bg-gray-900 dark:bg-gray-950 rounded-xl overflow-hidden shadow-2xl border border-primary-200/20 dark:border-primary-700/20">
          <div class="bg-gray-800 dark:bg-gray-900 px-4 py-3 border-b border-gray-700 dark:border-gray-800">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-2">
                <div class="w-3 h-3 bg-red-500 rounded-full"></div>
                <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
                <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                <span class="ml-4 text-gray-300 dark:text-gray-400 text-sm font-medium">Terminal Output</span>
              </div>
              <div v-if="isExecuting" class="flex items-center space-x-2">
                <div class="w-2 h-2 bg-primary-500 rounded-full animate-pulse"></div>
                <span class="text-primary-400 text-xs">LIVE</span>
              </div>
            </div>
          </div>
          <div class="p-4 max-h-96 overflow-auto">
            <pre class="text-primary-300 font-mono text-sm whitespace-pre-wrap">{{ output }}</pre>
          </div>
        </div>

        <!-- Network Tools Grid (if tools are enabled) -->
        <div v-if="hasToolEnable" class="border-t border-primary-200/30 dark:border-primary-700/30 pt-6">
          <h3 class="text-lg font-semibold text-gray-800 dark:text-gray-200 mb-4">Additional Network Tools</h3>
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <template v-for="tool in tools" :key="tool.label">
              <button
                v-if="tool.enable"
                @click="openTool(tool)"
                class="group relative overflow-hidden rounded-xl p-5 text-left bg-primary-50/30 dark:bg-gray-700/30 border border-primary-200/50 dark:border-gray-600/50 hover:border-transparent transition-all duration-300"
              >
                <div 
                  class="absolute -inset-px rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  :class="`bg-gradient-to-br ${tool.color}`"
                ></div>
                
                <div class="relative z-10 flex items-center space-x-4">
                  <div 
                    class="flex items-center justify-center w-12 h-12 rounded-xl flex-shrink-0 transition-all duration-300"
                    :class="[`bg-gradient-to-br ${tool.color}`, 'group-hover:bg-white/20 group-hover:scale-110']"
                  >
                    <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                    </svg>
                  </div>
                  <div>
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 group-hover:text-white transition-colors duration-300">{{ tool.label }}</h3>
                    <p class="text-sm text-gray-600 dark:text-gray-300 group-hover:text-white/80 transition-colors duration-300">{{ tool.description }}</p>
                  </div>
                  <svg class="w-6 h-6 text-gray-400 ml-auto group-hover:text-white transition-all duration-300 transform group-hover:translate-x-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                  </svg>
                </div>
              </button>
            </template>
          </div>
        </div>
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