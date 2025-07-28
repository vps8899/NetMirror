<template>
  <div class="space-y-4">
    <!-- Header with node count and refresh button - improved mobile layout -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
      <div class="text-sm text-gray-600 dark:text-gray-400 order-2 sm:order-1">
        {{ nodes.length }} node{{ nodes.length !== 1 ? 's' : '' }} available
      </div>
      <button
        @click="testAllLatencies"
        :disabled="loading"
        class="inline-flex items-center justify-center px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 order-1 sm:order-2 w-full sm:w-auto"
        :class="loading 
          ? 'bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400 cursor-not-allowed'
          : 'bg-primary-50 hover:bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:hover:bg-primary-900/50 dark:text-primary-400'"
      >
        <svg 
          class="w-4 h-4 mr-2" 
          :class="{ 'animate-spin': loading }"
          fill="none" 
          stroke="currentColor" 
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
        </svg>
        {{ loading ? 'Testing All Nodes...' : 'Refresh All Nodes' }}
      </button>
    </div>

    <!-- Node Grid with Pagination - enhanced mobile responsiveness -->
    <div class="relative">
      <!-- Navigation Buttons - hidden on mobile for cleaner look -->
      <button
        v-if="totalPages > 1"
        @click="goToPrevPage"
        class="absolute left-0 top-1/2 transform -translate-y-1/2 z-10 w-10 h-10 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm border border-gray-200 dark:border-gray-700 rounded-full shadow-lg transition-all duration-200 flex items-center justify-center opacity-0 hover:opacity-100 hover:bg-primary-50 dark:hover:bg-primary-900/30 hidden md:flex"
        @mouseenter="$event.target.style.opacity = '1'"
        @mouseleave="$event.target.style.opacity = '0'"
      >
        <svg class="w-5 h-5 text-gray-600 dark:text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
      </button>

      <button
        v-if="totalPages > 1"
        @click="goToNextPage"
        class="absolute right-0 top-1/2 transform -translate-y-1/2 z-10 w-10 h-10 bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm border border-gray-200 dark:border-gray-700 rounded-full shadow-lg transition-all duration-200 flex items-center justify-center opacity-0 hover:opacity-100 hover:bg-primary-50 dark:hover:bg-primary-900/30 hidden md:flex"
        @mouseenter="$event.target.style.opacity = '1'"
        @mouseleave="$event.target.style.opacity = '0'"
      >
        <svg class="w-5 h-5 text-gray-600 dark:text-gray-400 hover:text-primary-600 dark:hover:text-primary-400 transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      </button>

      <!-- Grid Container - 紧凑布局 -->
      <div class="relative" style="min-height: 140px;">
        <transition name="slide">
          <div :key="currentPage" class="grid grid-cols-2 md:grid-cols-4 gap-3 absolute inset-0">
            <template v-for="node in currentPageNodes" :key="node.url">
              <a
                :href="isCurrentNode(node) ? '#' : node.url"
                @click="isCurrentNode(node) && $event.preventDefault()"
                class="relative bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-lg transition-all duration-300 border border-gray-200 dark:border-gray-700 hover:border-primary-500 overflow-hidden group block no-underline"
                :class="{ 'ring-2 ring-primary-500 cursor-default': isCurrentNode(node), 'cursor-pointer': !isCurrentNode(node) }"
              >
                <!-- Background gradient on hover -->
                <div class="absolute inset-0 bg-gradient-to-br from-primary-500/10 to-primary-600/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300"></div>
                
                <!-- 紧凑卡片布局 -->
                <div class="relative p-3 pb-2 flex flex-col h-full min-h-[120px]">
                  <!-- Header with name and current badge - 超紧凑布局 -->
                  <div class="flex items-start justify-between mb-2">
                    <div class="flex-1 min-w-0">
                      <h3 class="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors leading-tight mb-0.5">
                        {{ node.name }}
                      </h3>
                      <p class="text-xs text-gray-600 dark:text-gray-400 leading-tight">{{ node.location }}</p>
                    </div>
                    <div v-if="isCurrentNode(node)" class="ml-1.5 flex-shrink-0">
                      <span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300">
                        Current
                      </span>
                    </div>
                  </div>

                  <!-- Status Section - 超紧凑状态显示 -->
                  <div class="flex items-center justify-between mb-2 flex-grow">
                    <!-- Latency with icon -->
                    <div class="flex items-center space-x-1.5">
                      <div
                        :key="`indicator-${node.name}`"
                        class="w-2.5 h-2.5 rounded-full flex-shrink-0"
                        :class="{
                          'bg-green-500': latencies[node.name]?.status === 'good',
                          'bg-yellow-500': latencies[node.name]?.status === 'medium',
                          'bg-red-500': latencies[node.name]?.status === 'high' || latencies[node.name]?.status === 'error',
                          'bg-gray-400 animate-pulse': !latencies[node.name]
                        }"
                      ></div>
                      <span :key="`latency-${node.name}`" class="text-xs font-semibold min-w-0" :class="{
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
                    
                    <!-- Status Badge - 超小状态徽章 -->
                    <div v-if="latencies[node.name]" :key="`status-${node.name}`" class="text-xs font-medium px-1.5 py-0.5 rounded flex-shrink-0" :class="{
                      'bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400': latencies[node.name].status === 'good',
                      'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-400': latencies[node.name].status === 'medium',
                      'bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-400': latencies[node.name].status === 'high',
                      'bg-gray-100 text-gray-700 dark:bg-gray-900/50 dark:text-gray-400': latencies[node.name].status === 'error'
                    }">
                      {{ getStatusText(latencies[node.name]?.status) }}
                    </div>
                  </div>

                  <!-- Bottom section - 超紧凑按钮区域 -->
                  <div class="flex items-center justify-center mt-auto pt-1">
                    <!-- Ping Button - 超小按钮 -->
                    <button
                      @click.stop.prevent="pingSingleNode(node)"
                      :disabled="pingStates[node.name]?.isPinging"
                      class="inline-flex items-center px-2 py-1.5 rounded text-xs font-medium transition-all duration-200 w-full justify-center"
                      :class="pingStates[node.name]?.isPinging 
                        ? 'bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400 cursor-not-allowed'
                        : 'bg-primary-50 hover:bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:hover:bg-primary-900/50 dark:text-primary-400'"
                    >
                      <svg 
                        v-if="pingStates[node.name]?.isPinging" 
                        class="w-3 h-3 mr-1 animate-spin" 
                        fill="none" 
                        stroke="currentColor" 
                        viewBox="0 0 24 24"
                      >
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
                      </svg>
                      <svg 
                        v-else
                        class="w-3 h-3 mr-1" 
                        fill="currentColor" 
                        viewBox="0 0 24 24"
                      >
                        <path d="M13 10V3L4 14h7v7l9-11h-7z"/>
                      </svg>
                      <span>{{ pingStates[node.name]?.isPinging ? 'Testing...' : 'Test' }}</span>
                    </button>
                  </div>
                </div>
              </a>
            </template>
          </div>
        </transition>
      </div>
    </div>

    <!-- Pagination Indicators - improved mobile layout -->
    <div v-if="totalPages > 1" class="flex justify-center items-center space-x-3 pt-2">
      <!-- Mobile navigation buttons -->
      <button
        @click="goToPrevPage"
        class="md:hidden flex items-center justify-center w-8 h-8 rounded-full bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm border border-gray-200 dark:border-gray-700 shadow-sm transition-all duration-200 hover:bg-primary-50 dark:hover:bg-primary-900/30"
      >
        <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
      </button>
      
      <!-- Page indicators -->
      <div class="flex space-x-2">
        <button
          v-for="page in totalPages"
          :key="page"
          @click="currentPage = page - 1"
          class="w-2.5 h-2.5 rounded-full transition-all duration-200"
          :class="currentPage === page - 1 
            ? 'bg-primary-500 scale-125' 
            : 'bg-gray-300 dark:bg-gray-600 hover:bg-primary-400 dark:hover:bg-primary-600'"
        ></button>
      </div>
      
      <!-- Mobile navigation buttons -->
      <button
        @click="goToNextPage"
        class="md:hidden flex items-center justify-center w-8 h-8 rounded-full bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm border border-gray-200 dark:border-gray-700 shadow-sm transition-all duration-200 hover:bg-primary-50 dark:hover:bg-primary-900/30"
      >
        <svg class="w-4 h-4 text-gray-600 dark:text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
        </svg>
      </button>
    </div>

    <!-- Empty State - improved mobile styling -->
    <div v-if="nodes.length === 0 && !loading" class="text-center py-12">
      <div class="mx-auto w-16 h-16 bg-gradient-to-br from-gray-100 to-gray-200 dark:from-gray-700 dark:to-gray-800 rounded-full flex items-center justify-center mb-4">
        <svg class="w-8 h-8 text-gray-400 dark:text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"></path>
        </svg>
      </div>
      <h3 class="text-base font-medium text-gray-900 dark:text-gray-100 mb-2">No nodes available</h3>
      <p class="text-sm text-gray-500 dark:text-gray-400 max-w-sm mx-auto">No looking glass nodes have been configured yet. Please check back later.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()
const nodes = ref([])
const latencies = ref({}) // 使用 node.name 作为 key
const loading = ref(true)
const pingStates = ref({}) // 存储 ping 状态
const currentPage = ref(0)
const windowWidth = ref(typeof window !== 'undefined' ? window.innerWidth : 1024)

let latencyInterval = null

// 监听窗口大小变化
const handleResize = () => {
  windowWidth.value = window.innerWidth
  // 如果当前页超出了新的总页数，回到第一页
  if (currentPage.value >= totalPages.value) {
    currentPage.value = 0
  }
}

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

// Test latency for a single node (using ping)
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
      console.log(`Latency response for ${node.name}:`, data) // 调试信息
      if (data.success) {
        latencies.value[node.name] = {
          latency: latency,
          status: getStatusByLatency(latency)
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
  loading.value = true
  try {
    // Test nodes sequentially to avoid congestion
    for (const node of nodes.value) {
      await testNodeLatency(node)
      // Small delay between tests to avoid overwhelming the network
      await new Promise(resolve => setTimeout(resolve, 100))
    }
  } finally {
    loading.value = false
  }
}

// Manual ping for a single node
const pingSingleNode = async (node) => {
  pingStates.value[node.name] = { isPinging: true }
  await testNodeLatency(node)
  pingStates.value[node.name] = { isPinging: false }
}

// 分页相关 - 固定一行显示，通过翻页浏览
const nodesPerPage = computed(() => {
  // 固定每页显示数量，保持一行布局
  if (windowWidth.value < 768) {
    return 2  // 移动端：每页2个节点（一行2个）
  }
  return 4    // 桌面端：每页4个节点（一行4个）
})

const totalPages = computed(() => Math.ceil(nodes.value.length / nodesPerPage.value))

const currentPageNodes = computed(() => {
  const startIndex = currentPage.value * nodesPerPage.value
  const endIndex = startIndex + nodesPerPage.value
  return nodes.value.slice(startIndex, endIndex)
})

// 导航函数 - 循环滚动
const goToPrevPage = () => {
  if (currentPage.value > 0) {
    currentPage.value--
  } else {
    // 循环到最后一页
    currentPage.value = totalPages.value - 1
  }
}

const goToNextPage = () => {
  if (currentPage.value < totalPages.value - 1) {
    currentPage.value++
  } else {
    // 循环到第一页
    currentPage.value = 0
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

const getStatusByLatency = (latency) => {
  if (latency < 200) return 'good'
  if (latency < 500) return 'medium'
  return 'high'
}

onMounted(() => {
  fetchNodes()
  
  // 添加窗口大小变化监听
  window.addEventListener('resize', handleResize)
  
  // Refresh latencies every 5 minutes (300,000 ms) to reduce system load.
  latencyInterval = setInterval(() => {
    testAllLatencies()
  }, 300000)
})

onUnmounted(() => {
  if (latencyInterval) {
    clearInterval(latencyInterval)
  }
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
/* Page transition - 使用淡入淡出 + 缩放，避免移动到容器外部 */
.slide-enter-active,
.slide-leave-active {
  transition: all 0.3s ease-out;
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  width: 100%;
}

.slide-enter-from {
  opacity: 0;
  transform: scale(0.95);
}

.slide-enter-to,
.slide-leave-from {
  opacity: 1;
  transform: scale(1);
}

.slide-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>
