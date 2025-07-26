<template>
  <div class="space-y-4">
    <!-- Current Node Info -->
    <div v-if="currentNode" class="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 border-2 border-primary-500">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ currentNode.name }}</h3>
          <p class="text-sm text-gray-600 dark:text-gray-400">{{ currentNode.location }}</p>
        </div>
        <div class="text-sm font-medium text-primary-600 dark:text-primary-400">
          Current Node
        </div>
      </div>
    </div>

    <!-- Node Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      <div
        v-for="node in nodes"
        :key="node.url"
        @click="navigateToNode(node)"
        class="relative bg-white dark:bg-gray-800 rounded-lg shadow-md hover:shadow-lg transition-all duration-300 cursor-pointer border border-gray-200 dark:border-gray-700 hover:border-primary-500 overflow-hidden group"
        :class="{ 'ring-2 ring-primary-500': node.current }"
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
            <div v-if="node.current" class="ml-3">
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300">
                Current
              </span>
            </div>
          </div>

          <!-- Latency Display -->
          <div class="mt-4 flex items-center justify-between">
            <div class="flex items-center space-x-2">
              <div
                class="w-2 h-2 rounded-full animate-pulse"
                :class="{
                  'bg-green-500': latencies[node.url]?.status === 'good',
                  'bg-yellow-500': latencies[node.url]?.status === 'medium',
                  'bg-red-500': latencies[node.url]?.status === 'high' || latencies[node.url]?.status === 'error',
                  'bg-gray-400': !latencies[node.url]
                }"
              ></div>
              <span class="text-sm font-medium" :class="{
                'text-green-600 dark:text-green-400': latencies[node.url]?.status === 'good',
                'text-yellow-600 dark:text-yellow-400': latencies[node.url]?.status === 'medium',
                'text-red-600 dark:text-red-400': latencies[node.url]?.status === 'high' || latencies[node.url]?.status === 'error',
                'text-gray-600 dark:text-gray-400': !latencies[node.url]
              }">
                <span v-if="!latencies[node.url]">Testing...</span>
                <span v-else-if="latencies[node.url].status === 'error'">Offline</span>
                <span v-else>{{ latencies[node.url].latency }}ms</span>
              </span>
            </div>
            
            <!-- Status Badge -->
            <div v-if="latencies[node.url]" class="text-xs font-medium px-2 py-1 rounded-full" :class="{
              'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': latencies[node.url].status === 'good',
              'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': latencies[node.url].status === 'medium',
              'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': latencies[node.url].status === 'high',
              'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': latencies[node.url].status === 'error'
            }">
              {{ getStatusText(latencies[node.url]?.status) }}
            </div>
          </div>

          <!-- Click hint -->
          <div class="mt-4 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            <svg class="w-5 h-5 text-primary-500 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"></path>
            </svg>
            <span class="text-sm text-primary-600 dark:text-primary-400 font-medium">Visit Node</span>
          </div>
        </div>
      </div>
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
import axios from 'axios'

const nodes = ref([])
const currentNode = ref(null)
const latencies = ref({})
const loading = ref(true)

let latencyInterval = null

// Fetch nodes list
const fetchNodes = async () => {
  try {
    const response = await axios.get('/nodes')
    if (response.data.success) {
      nodes.value = response.data.nodes || []
      // Start testing latencies
      testAllLatencies()
    }
  } catch (error) {
    console.error('Failed to fetch nodes:', error)
  } finally {
    loading.value = false
  }
}

// Fetch current node info
const fetchCurrentNode = async () => {
  try {
    const response = await axios.get('/nodes/current')
    if (response.data.success) {
      currentNode.value = response.data.current
    }
  } catch (error) {
    console.error('Failed to fetch current node:', error)
  }
}

// Test latency for a single node
const testNodeLatency = async (node) => {
  try {
    const startTime = Date.now()
    const response = await axios.get('/nodes/latency', {
      params: { url: node.url },
      timeout: 5000
    })
    const endTime = Date.now()
    
    if (response.data.success) {
      const latency = endTime - startTime
      
      // Determine status based on latency
      let status = 'good'
      if (latency > 200) {
        status = 'high'
      } else if (latency > 100) {
        status = 'medium'
      }
      
      latencies.value[node.url] = {
        latency: latency,
        status: status
      }
    }
  } catch (error) {
    console.error('Failed to test latency for', node.name, error)
    latencies.value[node.url] = {
      latency: -1,
      status: 'error'
    }
  }
}

// Test all node latencies
const testAllLatencies = async () => {
  // Test all nodes in parallel
  const promises = nodes.value.map(node => testNodeLatency(node))
  await Promise.all(promises)
}

// Navigate to selected node
const navigateToNode = (node) => {
  if (!node.current && node.url) {
    window.location.href = node.url
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
  fetchCurrentNode()
  fetchNodes()
  
  // Refresh latencies every 30 seconds
  latencyInterval = setInterval(() => {
    testAllLatencies()
  }, 30000)
})

onUnmounted(() => {
  if (latencyInterval) {
    clearInterval(latencyInterval)
  }
})
</script>