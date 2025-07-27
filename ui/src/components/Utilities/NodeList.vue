<template>
  <div class="space-y-3">
    <!-- Control Panel -->
    <div class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
        <div class="flex items-center space-x-4">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Looking Glass Nodes</h3>
          <span class="text-sm text-gray-500 dark:text-gray-400">
            {{ nodes.length }} nodes available
          </span>
        </div>
        
        <div class="flex items-center space-x-3">
          <!-- Refresh Button -->
          <button
            @click="refreshNodes"
            :disabled="loading"
            class="inline-flex items-center px-3 py-2 rounded-lg font-medium text-sm transition-all duration-200 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300"
          >
            <svg class="w-4 h-4" :class="{ 'animate-spin': loading }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
            </svg>
          </button>
        </div>
      </div>
    </div>

    <!-- Node Grid with True Virtual Pagination -->
    <div class="relative px-4 md:px-0">
      <!-- Navigation Buttons for Desktop -->
      <button
        v-if="canScrollLeft && !isMobile"
        @click="scrollLeft"
        class="absolute left-0 top-1/2 transform -translate-y-1/2 -translate-x-12 z-10 w-10 h-10 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-full shadow-lg hover:shadow-xl transition-all duration-200 flex items-center justify-center group hover:bg-primary-50 dark:hover:bg-primary-900/30"
      >
        <svg class="w-5 h-5 text-gray-600 dark:text-gray-400 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
      </button>

      <button
        v-if="canScrollRight && !isMobile"
        @click="scrollRight"
        class="absolute right-0 top-1/2 transform -translate-y-1/2 translate-x-12 z-10 w-10 h-10 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-full shadow-lg hover:shadow-xl transition-all duration-200 flex items-center justify-center group hover:bg-primary-50 dark:hover:bg-primary-900/30"
      >
        <svg class="w-5 h-5 text-gray-600 dark:text-gray-400 group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      </button>

      <!-- Grid Container with True Pagination (no transform) -->
      <div class="overflow-visible">
        <transition
          name="page-fade"
          mode="out-in"
        >
          <div :key="currentPage" class="w-full">
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
              <a
                v-for="node in currentPageNodes"
                :key="node.url"
                :href="isCurrentNode(node) ? '#' : node.url"
                @click="isCurrentNode(node) && $event.preventDefault()"
                class="relative bg-white dark:bg-gray-800 rounded-lg shadow-sm hover:shadow-md transition-all duration-300 border border-gray-200 dark:border-gray-700 hover:border-primary-500 overflow-hidden group block no-underline"
                :class="{ 'ring-2 ring-primary-500 cursor-default': isCurrentNode(node), 'cursor-pointer': !isCurrentNode(node) }"
              >
                <!-- Background gradient on hover -->
                <div class="absolute inset-0 bg-gradient-to-br from-primary-500/10 to-primary-600/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                
                <div class="relative p-4">
                  <!-- Header with name and current badge -->
                  <div class="flex items-start justify-between mb-2">
                    <div class="flex-1 min-w-0">
                      <h3 class="text-base font-semibold text-gray-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors truncate">
                        {{ node.name }}
                      </h3>
                      <p class="text-xs text-gray-600 dark:text-gray-400 truncate">{{ node.location }}</p>
                    </div>
                    <div v-if="isCurrentNode(node)" class="ml-2 flex-shrink-0">
                      <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300">
                        Current
                      </span>
                    </div>
                  </div>

                  <!-- Compact Status Section -->
                  <div class="flex items-center justify-between mb-2">
                    <!-- Latency with icon -->
                    <div class="flex items-center space-x-1.5">
                      <div
                        class="w-2 h-2 rounded-full flex-shrink-0"
                        :class="{
                          'bg-green-500': pingResults[node.name]?.status === 'good',
                          'bg-yellow-500': pingResults[node.name]?.status === 'medium',
                          'bg-red-500': pingResults[node.name]?.status === 'high' || pingResults[node.name]?.status === 'error',
                          'bg-gray-400 animate-pulse': !pingResults[node.name] || pingStates[node.name]?.isPinging
                        }"
                      ></div>
                      <span class="text-sm font-medium min-w-0" :class="{
                        'text-green-600 dark:text-green-400': pingResults[node.name]?.status === 'good',
                        'text-yellow-600 dark:text-yellow-400': pingResults[node.name]?.status === 'medium',
                        'text-red-600 dark:text-red-400': pingResults[node.name]?.status === 'high' || pingResults[node.name]?.status === 'error',
                        'text-gray-600 dark:text-gray-400': !pingResults[node.name]
                      }">
                        <span v-if="pingStates[node.name]?.isPinging" class="text-xs">Pinging...</span>
                        <span v-else-if="!pingResults[node.name]" class="text-xs">Testing...</span>
                        <span v-else-if="pingResults[node.name].status === 'error'" class="text-xs">Offline</span>
                        <span v-else class="text-sm">{{ pingResults[node.name].averageLatency }}ms</span>
                      </span>
                    </div>
                    
                    <!-- Compact Status Badge -->
                    <div v-if="pingResults[node.name] && !pingStates[node.name]?.isPinging" class="text-xs font-medium px-2 py-0.5 rounded-full flex-shrink-0" :class="{
                      'bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400': pingResults[node.name].status === 'good',
                      'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-400': pingResults[node.name].status === 'medium',
                      'bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-400': pingResults[node.name].status === 'high',
                      'bg-gray-100 text-gray-700 dark:bg-gray-900/50 dark:text-gray-400': pingResults[node.name].status === 'error'
                    }">
                      {{ getStatusText(pingResults[node.name]?.status) }}
                    </div>
                  </div>

                  <!-- Ping Results (only for manual ping) -->
                  <div v-if="pingResults[node.name] && pingResults[node.name].status !== 'error' && pingResults[node.name].packetsSent > 1" class="text-xs text-gray-600 dark:text-gray-400 mb-2">
                    <div class="flex justify-between">
                      <span>Min: {{ pingResults[node.name].minLatency }}ms</span>
                      <span>Max: {{ pingResults[node.name].maxLatency }}ms</span>
                    </div>
                    <div class="flex justify-between">
                      <span>Loss: {{ pingResults[node.name].packetLoss }}%</span>
                      <span>Count: {{ pingResults[node.name].packetsSent }}</span>
                    </div>
                  </div>

                  <!-- Action Button and Visit hint -->
                  <div class="flex items-center justify-between">
                    <!-- Ping Button -->
                    <button
                      @click.stop.prevent="pingSingleNode(node)"
                      :disabled="pingStates[node.name]?.isPinging"
                      class="inline-flex items-center px-2 py-1 rounded text-xs font-medium transition-all duration-200"
                      :class="pingStates[node.name]?.isPinging
                        ? 'bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500 cursor-not-allowed'
                        : 'bg-primary-50 hover:bg-primary-100 dark:bg-primary-900/30 dark:hover:bg-primary-900/50 text-primary-700 dark:text-primary-400'"
                    >
                      <svg v-if="pingStates[node.name]?.isPinging" class="w-3 h-3 mr-1 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <circle cx="12" cy="12" r="10" stroke-width="4" stroke-opacity="0.25"/>
                        <path d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 714 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" fill="currentColor"/>
                      </svg>
                      <svg v-else class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                      </svg>
                      {{ pingStates[node.name]?.isPinging ? 'Pinging...' : 'Ping' }}
                    </button>

                    <!-- Visit hint (compact) -->
                    <div class="flex items-center opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                      <svg v-if="!isCurrentNode(node)" class="w-4 h-4 text-primary-500 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6"></path>
                      </svg>
                      <span class="text-xs text-primary-600 dark:text-primary-400 font-medium">
                        {{ isCurrentNode(node) ? 'Current Node' : 'Visit Node' }}
                      </span>
                    </div>
                  </div>
                </div>
              </a>
            </div>
          </div>
        </transition>
      </div>
      
      <!-- Mobile Navigation Controls -->
      <div v-if="isMobile && totalPages > 1" class="flex items-center justify-between mt-4">
        <button
          @click="scrollLeft"
          :disabled="!canScrollLeft"
          class="px-3 py-2 rounded-lg font-medium text-sm transition-all duration-200"
          :class="canScrollLeft 
            ? 'bg-primary-50 hover:bg-primary-100 dark:bg-primary-900/30 dark:hover:bg-primary-900/50 text-primary-700 dark:text-primary-400' 
            : 'bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500 cursor-not-allowed'"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
          </svg>
        </button>
        
        <span class="text-sm text-gray-600 dark:text-gray-400">
          Page {{ currentPage + 1 }} / {{ totalPages }}
        </span>
        
        <button
          @click="scrollRight"
          :disabled="!canScrollRight"
          class="px-3 py-2 rounded-lg font-medium text-sm transition-all duration-200"
          :class="canScrollRight 
            ? 'bg-primary-50 hover:bg-primary-100 dark:bg-primary-900/30 dark:hover:bg-primary-900/50 text-primary-700 dark:text-primary-400' 
            : 'bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500 cursor-not-allowed'"
        >
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
          </svg>
        </button>
      </div>
    </div>

    <!-- Page Indicators (Desktop only) -->
    <div v-if="totalPages > 1 && !isMobile" class="flex justify-center space-x-2">
      <button
        v-for="page in totalPages"
        :key="page"
        @click="goToPage(page - 1)"
        class="w-2 h-2 rounded-full transition-all duration-200"
        :class="currentPage === page - 1 
          ? 'bg-primary-500 scale-125' 
          : 'bg-gray-300 dark:bg-gray-600 hover:bg-primary-400 dark:hover:bg-primary-600'"
      ></button>
    </div>

    <!-- Empty State -->
    <div v-if="nodes.length === 0 && !loading" class="text-center py-8">
      <svg class="mx-auto h-10 w-10 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03-3-9s1.343-9 3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 919-9"></path>
      </svg>
      <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">No nodes configured</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watchEffect } from 'vue'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const nodes = ref([])
const pingResults = ref({}) // 存储 ping 结果
const pingStates = ref({}) // 存储 ping 状态
const loading = ref(true)

// 分页相关
const currentPage = ref(0)
const isMobile = ref(false)
const nodesPerPage = computed(() => {
  if (isMobile.value) return 4 // 移动端每页4个
  return 8 // 桌面端每页8个
})

// 计算总页数
const totalPages = computed(() => {
  if (nodes.value.length === 0) return 0
  return Math.ceil(nodes.value.length / nodesPerPage.value)
})

// 计算当前页的节点 - 真正的虚拟分页，只渲染当前页
const currentPageNodes = computed(() => {
  const startIndex = currentPage.value * nodesPerPage.value
  const endIndex = startIndex + nodesPerPage.value
  return nodes.value.slice(startIndex, endIndex)
})

// 检测移动端
const checkMobile = () => {
  isMobile.value = window.innerWidth < 768
}

// 监听窗口大小变化
watchEffect(() => {
  // 当每页节点数变化时，调整当前页
  if (currentPage.value >= totalPages.value && totalPages.value > 0) {
    currentPage.value = totalPages.value - 1
  }
})

// 是否可以向左翻页
const canScrollLeft = computed(() => {
  return currentPage.value > 0
})

// 是否可以向右翻页  
const canScrollRight = computed(() => {
  return currentPage.value < totalPages.value - 1
})

// 向左翻页
const scrollLeft = () => {
  if (canScrollLeft.value) {
    currentPage.value--
  }
}

// 向右翻页
const scrollRight = () => {
  if (canScrollRight.value) {
    currentPage.value++
  }
}

// 跳转到指定页面
const goToPage = (page) => {
  if (page >= 0 && page < totalPages.value) {
    currentPage.value = page
  }
}

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
      console.log('Fetched nodes:', nodes.value)
      // Start testing latencies immediately
      testAllLatencies()
      // 重置到第一页
      currentPage.value = 0
    }
  } catch (error) {
    console.error('Failed to fetch nodes:', error)
  } finally {
    loading.value = false
  }
}

// Test latency for a single node (original auto-ping)
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
      const latency = Date.now() - timestamp
      console.log(`Latency response for ${node.name}:`, data)
      if (data.success) {
        // 使用简单的延迟结果作为初始显示
        pingResults.value[node.name] = {
          averageLatency: latency,
          minLatency: latency,
          maxLatency: latency,
          packetsSent: 1,
          packetsReceived: 1,
          packetLoss: 0,
          status: getStatusByLatency(latency, 0)
        }
        console.log(`Updated latencies for ${node.name}:`, pingResults.value[node.name])
      } else {
        throw new Error('Server returned error')
      }
    } else {
      throw new Error('Server not responding properly')
    }
  } catch (error) {
    // 如果是超时或网络错误，标记为offline
    console.error('Failed to test latency for', node.name, error)
    pingResults.value[node.name] = {
      averageLatency: 0,
      minLatency: 0,
      maxLatency: 0,
      packetsSent: 1,
      packetsReceived: 0,
      packetLoss: 100,
      status: 'error'
    }
  }
}

// Test all node latencies (auto-ping)
const testAllLatencies = async () => {
  // Test nodes sequentially to avoid congestion
  for (const node of nodes.value) {
    await testNodeLatency(node)
    // Small delay between tests to avoid overwhelming the network
    await new Promise(resolve => setTimeout(resolve, 100))
  }
}

// 执行单个节点的 ping
const pingSingleNode = async (node) => {
  pingStates.value[node.name] = { isPinging: true }
  await testNodeLatency(node)
  pingStates.value[node.name] = { isPinging: false }
}

// 刷新节点列表
const refreshNodes = async () => {
  loading.value = true
  // 不清空现有状态，只刷新节点列表
  await fetchNodes()
}

// Get human-readable status text
const getStatusText = (status) => {
  switch (status) {
    case 'good': return 'Excellent'
    case 'medium': return 'Good'
    case 'high': return 'Slow'
    case 'error': return 'Failed'
    default: return 'Unknown'
  }
}

const getStatusByLatency = (latency, packetLoss = 0) => {
  if (packetLoss > 10 || latency <= 0) return 'error'
  if (latency < 100) return 'good'
  if (latency < 300) return 'medium'
  return 'high'
}

onMounted(() => {
  checkMobile()
  window.addEventListener('resize', checkMobile)
  fetchNodes()
  
  // Refresh latencies every 5 minutes (300,000 ms) to reduce system load.
  latencyInterval = setInterval(() => {
    testAllLatencies()
  }, 300000)
})

onUnmounted(() => {
  window.removeEventListener('resize', checkMobile)
  if (latencyInterval) {
    clearInterval(latencyInterval)
  }
})
</script>

<style scoped>
/* Page transition animations */
.page-fade-enter-active {
  transition: all 0.3s ease-out;
}

.page-fade-leave-active {
  transition: all 0.2s ease-in;
}

.page-fade-enter-from {
  opacity: 0;
  transform: translateY(10px);
}

.page-fade-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
</style>