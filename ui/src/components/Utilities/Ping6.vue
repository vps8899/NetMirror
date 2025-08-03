<script setup>
import { ref, onMounted } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useNodeTool } from '@/composables/useNodeTool'
import { PlayIcon, StopIcon, SignalIcon } from '@heroicons/vue/24/outline'

const {
  working,
  selectedNode,
  isNodeReady,
  selectedNodeName,
  selectedNodeLocation,
  startTool,
  stopTool
} = useNodeTool()

const records = ref([])
const host = ref('')
const inputRef = ref()
const tableRef = ref()

const { apply: applyTable } = useMotion(tableRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 300 } }
})

const handlePing6Message = (e) => {
  const data = JSON.parse(e.data)
  let record = {
    host: '-',
    seq: data.seq,
    ttl: '-',
    latency: '-',
    isTimeout: data.is_timeout
  }

  if (!data.is_timeout) {
    record.host = data.from
    record.ttl = data.ttl
    record.latency = data.latency / 1000000
  }

  records.value.push(record)
  
  // Auto scroll to bottom
  setTimeout(() => {
    const table = tableRef.value
    if (table) {
      table.scrollTop = table.scrollHeight
    }
  }, 100)
}

const ping6 = async () => {
  if (working.value) {
    stopTool()
    return
  }
  
  if (!host.value.trim()) {
    inputRef.value?.focus()
    return
  }
  
  records.value = []
  
  const success = await startTool(
    'ping6', 
    { ip: host.value }, 
    'Ping6', 
    handlePing6Message
  )
  
  if (!success) {
    // startTool已经处理了错误显示
    return
  }
}

const getLatencyColor = (latency) => {
  if (latency === '-') return 'text-red-500 dark:text-red-400'
  if (latency < 50) return 'text-green-600 dark:text-green-400'
  if (latency < 100) return 'text-yellow-600 dark:text-yellow-400'
  return 'text-orange-500 dark:text-orange-400'
}

onMounted(() => {
  inputRef.value?.focus()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Node Selection Info -->
    <div v-if="selectedNode" class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-700 rounded-xl p-4">
      <div class="flex items-center">
        <div class="w-2 h-2 bg-green-500 rounded-full mr-3"></div>
        <div>
          <h3 class="font-medium text-green-900 dark:text-green-100">Running on {{ selectedNodeName }}</h3>
          <p class="text-sm text-green-700 dark:text-green-300">{{ selectedNodeLocation }}</p>
        </div>
      </div>
    </div>
    
    <!-- Input Section -->
    <div class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="relative flex-1">
          <SignalIcon class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            ref="inputRef"
            v-model="host"
            :disabled="working"
            type="text"
            placeholder="Enter IPv6 address or domain name"
            class="w-full pl-10 pr-4 py-3 bg-transparent border-0 rounded-xl focus:ring-0 transition-all duration-200 disabled:opacity-50 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400"
            @keyup.enter="ping6"
          />
        </div>
        <button
          @click="ping6"
          :disabled="!host.trim()"
          class="inline-flex items-center justify-center px-6 py-3 rounded-xl font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          :class="working 
            ? 'bg-red-500 hover:bg-red-600 text-white' 
            : 'bg-primary-500 hover:bg-primary-600 text-white hover:shadow-lg'"
        >
          <component :is="working ? StopIcon : PlayIcon" class="w-5 h-5 mr-2" />
          {{ working ? 'Stop' : 'Start Ping IPv6' }}
        </button>
      </div>
    </div>

    <!-- Results Section -->
    <div v-if="records.length > 0" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden shadow-sm">
      <div class="overflow-x-auto max-h-[30rem] overflow-y-auto" ref="tableRef">
        <table class="w-full text-sm">
          <thead class="bg-gray-50 dark:bg-gray-700/50 sticky top-0 z-10">
            <tr>
              <th class="px-6 py-3 text-left font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Seq</th>
              <th class="px-6 py-3 text-left font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Host</th>
              <th class="px-6 py-3 text-left font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">TTL</th>
              <th class="px-6 py-3 text-left font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Latency</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr 
              v-for="(record, index) in records" 
              :key="index"
              class="hover:bg-gray-50/50 dark:hover:bg-gray-700/30 transition-colors duration-150"
              :class="{ 'bg-red-50/50 dark:bg-red-900/20': record.isTimeout }"
            >
              <td class="px-6 py-3 whitespace-nowrap font-mono text-gray-700 dark:text-gray-300">
                {{ record.seq }}
              </td>
              <td class="px-6 py-3 whitespace-nowrap font-mono text-gray-700 dark:text-gray-300" :class="{ 'text-red-600 dark:text-red-400': record.host && record.host.startsWith('Error') }">
                {{ record.host }}
              </td>
              <td class="px-6 py-3 whitespace-nowrap font-mono text-gray-700 dark:text-gray-300">
                {{ record.ttl }}
              </td>
              <td class="px-6 py-3 whitespace-nowrap font-mono font-semibold" :class="getLatencyColor(record.latency)">
                {{ record.latency === '-' ? 'Timeout' : `${record.latency.toFixed(2)} ms` }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!working" class="text-center py-12">
      <SignalIcon class="w-16 h-16 text-gray-400/50 dark:text-gray-500/50 mx-auto mb-4" />
      <h3 class="text-lg font-medium text-gray-700 dark:text-gray-300 mb-2">Ready to Ping IPv6</h3>
      <p class="text-gray-500 dark:text-gray-400">Enter an IPv6 address or domain name to start testing connectivity.</p>
    </div>
  </div>
</template>