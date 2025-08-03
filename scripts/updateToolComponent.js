/**
 * 批量更新工具组件的脚本
 * 将所有网络诊断工具组件转换为使用节点管理系统
 */

// 标准模板映射
const TEMPLATE_MAP = {
  'ping': { 
    color: 'primary', 
    icon: '[Tool specific icon]', 
    event: 'Ping', 
    title: 'Ping',
    description: 'Ping connectivity test'
  },
  'mtr': { 
    color: 'purple', 
    icon: 'ChartBarIcon', 
    event: 'MTROutput', 
    title: 'MTR',
    description: 'Network path analysis'
  },
  'traceroute': { 
    color: 'blue', 
    icon: 'ArrowTrendingUpIcon', 
    event: 'MethodOutput', 
    title: 'Traceroute',
    description: 'Route discovery'
  },
  'speedtest': { 
    color: 'orange', 
    icon: '[Tool specific icon]', 
    event: 'SpeedtestOutput', 
    title: 'Speed Test',
    description: 'Network speed measurement'
  },
  'shell': { 
    color: 'gray', 
    icon: '[Tool specific icon]', 
    event: 'ShellOutput', 
    title: 'Shell',
    description: 'Interactive command line'
  }
}

// 标准组件模板
const COMPONENT_TEMPLATE = (tool) => `
<script setup>
import { ref, onMounted } from 'vue'
import { useNodeTool } from '@/composables/useNodeTool'
import { PlayIcon, StopIcon } from '@heroicons/vue/24/outline'
${tool.icon && tool.icon !== '[Tool specific icon]' ? `import { ${tool.icon} } from '@heroicons/vue/24/outline'` : ''}

const {
  working,
  selectedNodeName,
  selectedNodeLocation,
  startTool,
  stopTool
} = useNodeTool()

const output = ref('')
const host = ref('')
const inputRef = ref()
const outputRef = ref()

const handleMessage = (e) => {
  try {
    const data = JSON.parse(e.data)
    if (data.output) {
      output.value += data.output
    }
  } catch (error) {
    output.value += e.data // Handle plain text
  }
  
  // Auto scroll to bottom
  setTimeout(() => {
    const container = outputRef.value
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  }, 50)
}

const runTool = async () => {
  if (working.value) {
    stopTool()
    return
  }
  
  if (!host.value.trim()) {
    inputRef.value?.focus()
    return
  }
  
  output.value = ''
  
  const success = await startTool(
    '${tool.method || tool.title.toLowerCase()}', 
    { ip: host.value }, 
    '${tool.event}', 
    handleMessage
  )
  
  if (!success) return
}

onMounted(() => {
  inputRef.value?.focus()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Node Selection Info -->
    <div v-if="selectedNode" class="bg-${tool.color}-50 dark:bg-${tool.color}-900/20 border border-${tool.color}-200 dark:border-${tool.color}-700 rounded-xl p-4">
      <div class="flex items-center">
        <div class="w-2 h-2 bg-${tool.color}-500 rounded-full mr-3"></div>
        <div>
          <h3 class="font-medium text-${tool.color}-900 dark:text-${tool.color}-100">Running ${tool.title} on {{ selectedNodeName }}</h3>
          <p class="text-sm text-${tool.color}-700 dark:text-${tool.color}-300">{{ selectedNodeLocation }}</p>
        </div>
      </div>
    </div>

    <!-- Input Section -->
    <div class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="relative flex-1">
          ${tool.icon !== '[Tool specific icon]' ? `<${tool.icon} class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />` : ''}
          <input
            ref="inputRef"
            v-model="host"
            :disabled="working"
            type="text"
            placeholder="Enter IP address or domain name"
            class="w-full ${tool.icon !== '[Tool specific icon]' ? 'pl-10' : 'pl-4'} pr-4 py-3 bg-transparent border-0 rounded-xl focus:ring-0 transition-all duration-200 disabled:opacity-50 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400"
            @keyup.enter="runTool"
          />
        </div>
        <button
          @click="runTool"
          :disabled="!host.trim()"
          class="inline-flex items-center justify-center px-6 py-3 rounded-xl font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          :class="working 
            ? 'bg-red-500 hover:bg-red-600 text-white' 
            : 'bg-${tool.color}-500 hover:bg-${tool.color}-600 text-white hover:shadow-lg'"
        >
          <component :is="working ? StopIcon : PlayIcon" class="w-5 h-5 mr-2" />
          {{ working ? 'Stop' : 'Start ${tool.title}' }}
        </button>
      </div>
    </div>

    <!-- Results Section -->
    <div v-if="output" class="bg-gray-900 dark:bg-gray-950 rounded-xl border border-gray-700 overflow-hidden shadow-sm">
      <div class="px-4 py-3 bg-gray-800 dark:bg-gray-900 border-b border-gray-700">
        <div class="flex items-center justify-between">
          <h3 class="text-sm font-medium text-gray-300">${tool.title} Report to {{ host }}</h3>
          <span class="text-xs text-gray-400" v-if="working">Running...</span>
          <span class="text-xs text-green-400" v-else>Completed</span>
        </div>
      </div>
      <div 
        ref="outputRef"
        class="p-4 text-xs font-mono text-gray-100 overflow-x-auto max-h-[30rem] overflow-y-auto whitespace-pre leading-relaxed"
        style="font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;"
      >{{ output }}</div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!working" class="text-center py-12">
      ${tool.icon && tool.icon !== '[Tool specific icon]' ? `<${tool.icon} class="w-16 h-16 text-gray-400/50 dark:text-gray-500/50 mx-auto mb-4" />` : '
        <svg class="w-16 h-16 text-gray-400/50 dark:text-gray-500/50 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z" />
        </svg>
      '}
      <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100">${tool.title} Network Analysis</h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mt-2">${tool.description}</p>
    </div>
  </div>
</template>
`

// 工具定义
const tools = [
  { method: 'mtr', title: 'MTR', event: 'MTROutput', icon: 'ChartBarIcon', color: 'purple', description: 'Network path analysis' },
  { method: 'traceroute', title: 'Traceroute', event: 'MethodOutput', icon: 'ArrowTrendingUpIcon', color: 'blue', description: 'Route discovery' },
  { method: 'traceroute6', title: 'Traceroute IPv6', event: 'MethodOutput', icon: 'ArrowTrendingUpIcon', color: 'pink', description: 'IPv6 route discovery' },
  { method: 'ping6', title: 'Ping IPv6', event: 'Ping', icon: '[Tool specific icon]', color: 'green', description: 'IPv6 connectivity test' },
  { method: 'mtr6', title: 'MTR IPv6', event: 'MTROutput', icon: 'ChartBarIcon', color: 'sky', description: 'IPv6 path analysis' }
]

console.log('Update command:')
tools.forEach(tool => {
  console.log(`Updating ${tool.title}...`)
})

console.log('Use:
npm run build
npm run dev')