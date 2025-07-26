<template>
  <div class="space-y-4">
    <!-- Node Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <a
        v-for="node in nodes"
        :key="node.url"
        :href="isCurrentNode(node) ? '#' : node.url"
        @click="isCurrentNode(node) && $event.preventDefault()"
        class="relative bg-white dark:bg-gray-800 rounded-lg shadow-md hover:shadow-lg transition-all duration-300 border border-gray-200 dark:border-gray-700 hover:border-primary-500 overflow-hidden group block no-underline"
        :class="{ 'ring-2 ring-primary-500 cursor-default': isCurrentNode(node), 'cursor-pointer': !isCurrentNode(node) }"
      >
        <!-- Background gradient on hover -->
        <div class="absolute inset-0 bg-gradient-to-br from-primary-500/10 to-primary-600/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
        
        <div class="relative p-6">
          <div class="flex items-start justify-between mb-3">
            <div class="flex-1">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors">
                {{ node.name }}
              </h3>
              <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ node.location }}</p>
            </div>
            <div v-if="isCurrentNode(node)" class="ml-3">
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300">
                Current
              </span>
            </div>
          </div>

          <!-- Latency Display -->
          <div class="mt-4 flex items-center justify-between">
            <div class="flex items-center space-x-2">
              <div
                :key="`indicator-${node.name}`"
                class="w-2 h-2 rounded-full animate-pulse"
                :class="{
                  'bg-green-500': latencies[node.name]?.status === 'good',
                  'bg-yellow-500': latencies[node.name]?.status === 'medium',
                  'bg-red-500': latencies[node.name]?.status === 'high' || latencies[node.name]?.status === 'error',
                  'bg-gray-400': !latencies[node.name]
                }"
              ></div>
              <span :key="`latency-${node.name}`" class="text-sm font-medium" :class="{
                'text-green-600 dark:text-green-400': latencies[node.name]?.status === 'good',
                'text-yellow-600 dark:text-yellow-400': latencies[node.name]?.status === 'medium',
                'text-red-600 dark:text-red-400': latencies[node.name]?.status === 'high' || latencies[node.name]?.status === 'error',
                'text-gray-600 dark:text-gray-400': !latencies[node.name]
              }">
                <span v-if="!latencies[node.name]">Testing...</span>
                <span v-else-if="latencies[node.name].status === 'error'">Offline</span>
                <span v-else>{{ latencies[node.name].latency }}ms</span>
              </span>
            </div>
            
            <!-- Status Badge -->
            <div v-if="latencies[node.name]" :key="`status-${node.name}`" class="text-xs font-medium px-2 py-1 rounded-full" :class="{
              'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': latencies[node.name].status === 'good',
              'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': latencies[node.name].status === 'medium',
              'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': latencies[node.name].status === 'high',
              'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': latencies[node.name].status === 'error'
            }">
              {{ getStatusText(latencies[node.name]?.status) }}
            </div>
          </div>

          <!-- Click hint -->
          <div class="mt-4 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            <svg v-if="!isCurrentNode(node)" class="w-5 h-5 text-primary-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"></path>
            </svg>
            <span class="text-sm text-primary-600 dark:text-primary-400 font-medium">
              {{ isCurrentNode(node) ? 'Current Node' : 'Visit Node' }}
            </span>
          </div>
        </div>
      </a>
    </div>

    <!-- Empty State -->
    <div v-if="nodes.length === 0 && !loading" class="text-center py-12">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path>
      </svg>
      <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">No nodes configured</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const nodes = ref([])
const latencies = ref({}) // 使用 node.name 作为 key
const loading = ref(true)

let latencyInterval = null

// Get current page URL
const getCurrentURL = () => {
  const protocol = window.location.protocol
  const host = window.location.host
  const port = window.location.port
  
  // Construct base URL
  let baseURL = `${protocol}//${window.location.hostname}`
  
  // Add port if it's not default for the protocol
  if (port && ((protocol === 'http:' && port !== '80') || (protocol === 'https:' && port !== '443'))) {
    baseURL += `:${port}`
  }
  
  return baseURL
}

// Check if a node is the current node
const isCurrentNode = (node) => {
  const currentURL = getCurrentURL()
  // Compare normalized URLs
  return node.url.replace(/\/$/, '') === currentURL.replace(/\/$/, '')
}

// Fetch nodes list
const fetchNodes = async () => {
  try {
    const response = await fetch('/nodes')
    const data = await response.json()
    if (data.success) {
      nodes.value = data.nodes || []
      console.log('Fetched nodes:', nodes.value) // 调试信息
      // Start testing latencies immediately
      testAllLatencies()
    }
  } catch (error) {
    console.error('Failed to fetch nodes:', error)
  } finally {
    loading.value = false
  }
}

// Test latency for a single node
const testNodeLatency = async (node) => {
  try {
    // Send timestamp with request
    const timestamp = Date.now()
    const targetUrl = isCurrentNode(node) ? '/nodes/latency' : `${node.url}/nodes/latency`
    
    const response = await fetch(`${targetUrl}?timestamp=${timestamp}`, {
      method: 'GET',
      mode: 'cors',
      cache: 'no-cache',
      signal: AbortSignal.timeout(5000) // 5 second timeout
    })
    
    if (response.ok) {
      const data = await response.json()
      console.log(`Latency response for ${node.name}:`, data) // 调试信息
      if (data.success) {
        latencies.value[node.name] = {
          latency: data.latency,
          status: data.status
        }
        console.log(`Updated latencies for ${node.name}:`, latencies.value[node.name]) // 调试信息
      } else {
        throw new Error('Server returned error')
      }
    } else {
      throw new Error('Server not responding properly')
    }
  } catch (error) {
    // 如果是超时或网络错误，标记为offline
    console.error('Failed to test latency for', node.name, error)
    latencies.value[node.name] = {
      latency: -1,
      status: 'error'
    }
  }
}

// Test all node latencies
const testAllLatencies = async () => {
  // Test nodes sequentially to avoid congestion
  for (const node of nodes.value) {
    await testNodeLatency(node)
    // Small delay between tests to avoid overwhelming the network
    await new Promise(resolve => setTimeout(resolve, 100))
  }
}

// Get human-readable status text
const getStatusText = (status) => {
  switch (status) {
    case 'good': return 'Excellent'
    case 'medium': return 'Good'
    case 'high': return 'Slow'
    case 'error': return 'Offline'
    default: return 'Unknown'
  }
}

onMounted(() => {
  fetchNodes()
  
  // Refresh latencies every 1 second
  latencyInterval = setInterval(() => {
    testAllLatencies()
  }, 1000)
})

onUnmounted(() => {
  if (latencyInterval) {
    clearInterval(latencyInterval)
  }
})
</script>