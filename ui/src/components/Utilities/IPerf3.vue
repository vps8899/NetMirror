<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useNodeTool } from '@/composables/useNodeTool'
import { useAppStore } from '@/stores/app'
import { PlayIcon, StopIcon, ServerIcon, ClockIcon } from '@heroicons/vue/24/outline'
import 'xterm/css/xterm.css'
import { Terminal } from 'xterm'
import { FitAddon } from '@xterm/addon-fit'
import Copy from '../Copy.vue'
import { toRaw, markRaw } from 'vue'

const {
  working,
  selectedNode,
  isNodeReady,
  selectedNodeName,
  selectedNodeLocation,
  addEventListener,
  removeEventListener,
  sendRequest,
  stopTool: stopNodeTool
} = useNodeTool()

const appStore = useAppStore()
// working is now managed by useNodeTool()
const port = ref(0)
const timeout = ref(60)
const timeoutPercentage = ref(0)
const timePass = ref(0)
let timeoutInterval = null

// 获取节点IP地址的函数
const getNodeIP = (version) => {
  if (selectedNode.value) {
    // 尝试从节点的配置中获取IP
    if (selectedNode.value.config) {
      if (version === 'ipv4') {
        return selectedNode.value.config.public_ipv4
      } else if (version === 'ipv6') {
        return selectedNode.value.config.public_ipv6
      }
    }
    
    // 尝试从节点URL中解析IP
    try {
      const url = new URL(selectedNode.value.url)
      const hostname = url.hostname
      
      // 如果是IPv6地址（包含在[]中）
      if (hostname.startsWith('[') && hostname.endsWith(']')) {
        if (version === 'ipv6') {
          return hostname.slice(1, -1) // 去掉[]
        }
      } else {
        // IPv4地址或域名
        if (version === 'ipv4') {
          return hostname
        }
      }
    } catch (error) {
      console.error('Failed to parse node URL:', error)
    }
  }
  
  // 回退到本地配置
  if (version === 'ipv4') {
    return appStore.config?.public_ipv4
  } else if (version === 'ipv6') {
    return appStore.config?.public_ipv6
  }
  
  return null
}

const terminal = new Terminal({
  theme: {
    background: '#1f2937',
    foreground: '#f9fafb',
    cursor: '#3b82f6'
  },
  fontFamily: 'JetBrains Mono, Consolas, Monaco, monospace',
  fontSize: 14,
  cursorBlink: true,
  scrollback: 1000,
})

const terminalRef = ref()
const fitAddon = new FitAddon()
const cardRef = ref()

const { apply } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 300 } }
})

const handlePortChange = (e) => {
  port.value = parseInt(e.data)
  startTimeout()
}

const handleMessage = (e) => {
  fitAddon.fit()
  const lines = e.data.split('\n')
  lines.forEach(line => {
    if (line.trim()) {
      terminal.writeln(line)
    }
  })
}

const startTimeout = () => {
  timePass.value = 0
  timeoutPercentage.value = 0
  
  timeoutInterval = setInterval(() => {
    timePass.value += 1
    timeoutPercentage.value = (timePass.value / timeout.value) * 100
    
    if (timePass.value >= timeout.value || !working.value) {
      clearInterval(timeoutInterval)
    }
  }, 1000)
}

const startServer = async () => {
  working.value = true
  terminal.clear()
  port.value = 0
  
  terminal.writeln('\x1b[1;33mStarting IPerf3 server...\x1b[0m')

  // 添加事件监听器
  addEventListener('Iperf3', handlePortChange)
  addEventListener('Iperf3Stream', handleMessage)

  try {
    await sendRequest('iperf3/server', {})
  } catch (e) {
    if (e.name !== 'AbortError') {
      terminal.writeln('\x1b[1;31mError: Failed to start server\x1b[0m')
    }
  }

  working.value = false
  timeoutPercentage.value = 0
  timePass.value = 0
  clearInterval(timeoutInterval)
}

const stopServer = () => {
  removeEventListener('Iperf3', handlePortChange)
  removeEventListener('Iperf3Stream', handleMessage)
  stopNodeTool()
  terminal.writeln('\r\n\x1b[1;31mIPerf3 Server stopped by user\x1b[0m')
}

onMounted(() => {
  terminal.loadAddon(fitAddon)
  terminal.open(toRaw(terminalRef.value))
  fitAddon.fit()
  apply()
  
  terminal.writeln('\x1b[1;32mWelcome to the IPerf3 Server Terminal\x1b[0m')
  terminal.writeln('\x1b[90mClick "Start Server" to begin...\x1b[0m')
  terminal.writeln('')
})

onUnmounted(() => {
  stopServer()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Node Selection Info -->
    <div v-if="selectedNode" class="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-700 rounded-xl p-4">
      <div class="flex items-center">
        <div class="w-2 h-2 bg-emerald-500 rounded-full mr-3"></div>
        <div>
          <h3 class="font-medium text-emerald-900 dark:text-emerald-100">Running IPerf3 on {{ selectedNodeName }}</h3>
          <p class="text-sm text-emerald-700 dark:text-emerald-300">{{ selectedNodeLocation }}</p>
        </div>
      </div>
    </div>

    <!-- Control Panel -->
    <div class="bg-white dark:bg-gray-800 rounded-xl p-6 shadow-sm border border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
        <div class="flex items-center space-x-4">
          <div class="flex items-center justify-center w-12 h-12 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl">
            <ServerIcon class="w-6 h-6 text-white" />
          </div>
          <div>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">IPerf3 Server</h3>
            <p class="text-sm text-gray-600 dark:text-gray-400">Network bandwidth measurement tool</p>
          </div>
        </div>
        
        <button
          @click="working ? stopServer() : startServer()"
          class="inline-flex items-center px-6 py-3 rounded-xl font-medium transition-all duration-200"
          :class="working 
            ? 'bg-red-500 hover:bg-red-600 text-white' 
            : 'bg-primary-500 hover:bg-primary-600 text-white hover:shadow-lg'"
        >
          <component :is="working ? StopIcon : PlayIcon" class="w-5 h-5 mr-2" />
          {{ working ? 'Stop Server' : 'Start Server' }}
        </button>
      </div>
      
      <!-- Progress Bar -->
      <div v-if="working && port" class="mt-6">
        <div class="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400 mb-2">
          <span class="flex items-center">
            <ClockIcon class="w-4 h-4 mr-1.5" />
            Session timeout
          </span>
          <span>{{ Math.ceil(timeout.value - timePass.value) }}s remaining</span>
        </div>
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
          <div 
            class="bg-gradient-to-r from-yellow-400 to-orange-500 h-2.5 rounded-full transition-all duration-1000"
            :style="{ width: `${timeoutPercentage.value}%` }"
          ></div>
        </div>
      </div>
    </div>

    <!-- Connection Info -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 -translate-y-4"
      enter-to-class="opacity-100 translate-y-0"
    >
      <div v-if="working && port" ref="cardRef" class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-6">
        <h4 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">Connection Commands</h4>
        <div class="space-y-3">
          <div v-if="getNodeIP('ipv4')" class="bg-white dark:bg-gray-800 rounded-lg p-3">
            <div class="flex items-center justify-between">
              <div class="truncate">
                <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">IPv4</p>
                <code class="text-sm font-mono text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">
                  iperf3 -c {{ getNodeIP('ipv4') }} -p {{ port }}
                </code>
              </div>
              <Copy :value="`iperf3 -c ${getNodeIP('ipv4')} -p ${port}`" />
            </div>
          </div>
          
          <div v-if="getNodeIP('ipv6')" class="bg-white dark:bg-gray-800 rounded-lg p-3">
            <div class="flex items-center justify-between">
              <div class="truncate">
                <p class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">IPv6</p>
                <code class="text-sm font-mono text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">
                  iperf3 -c {{ getNodeIP('ipv6') }} -p {{ port }}
                </code>
              </div>
              <Copy :value="`iperf3 -c ${getNodeIP('ipv6')} -p ${port}`" />
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Terminal -->
    <div class="bg-gray-900 rounded-xl overflow-hidden border border-gray-700 shadow-lg">
      <div class="flex items-center justify-between px-4 py-2 bg-gray-800 border-b border-gray-700">
        <div class="flex items-center space-x-2">
          <div class="w-3 h-3 bg-red-500 rounded-full"></div>
          <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
          <div class="w-3 h-3 bg-green-500 rounded-full"></div>
        </div>
        <span class="text-sm font-medium text-gray-300">IPerf3 Terminal</span>
        <div class="w-16"></div>
      </div>
      <div ref="terminalRef" class="h-96 p-4"></div>
    </div>
  </div>
</template>
