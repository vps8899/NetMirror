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
              <div
                @click="selectNode(node)"
                class="relative bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-lg transition-all duration-300 border border-gray-200 dark:border-gray-700 hover:border-primary-500 overflow-hidden group cursor-pointer"
                :class="{ 
                  'ring-2 ring-primary-500': selectedNode && selectedNode.url === node.url,
                  'ring-2 ring-blue-500': isCurrentNode(node) && (!selectedNode || selectedNode.url !== node.url)
                }"
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
                    <div class="ml-1.5 flex-shrink-0 flex flex-col space-y-1">
                      <div v-if="isCurrentNode(node)">
                        <span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">
                          Current
                        </span>
                      </div>
                      <div v-if="selectedNode && selectedNode.url === node.url">
                        <span class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-medium bg-primary-100 text-primary-800 dark:bg-primary-900 dark:text-primary-300">
                          Selected
                        </span>
                      </div>
                    </div>
                  </div>

                  <!-- Status Section - 超紧凑状态显示 -->
                  <div class="flex items-center justify-between mb-2 flex-grow">
                    <!-- Latency with icon -->
                    <div class="flex items-center space-x-1.5">
                      <div
                        :key="`indicator-${getNodeKey(node)}`"
                        class="w-2.5 h-2.5 rounded-full flex-shrink-0"
                        :class="{
                          'bg-green-500': latencies[getNodeKey(node)]?.status === 'good',
                          'bg-yellow-500': latencies[getNodeKey(node)]?.status === 'medium',
                          'bg-red-500': latencies[getNodeKey(node)]?.status === 'high' || latencies[getNodeKey(node)]?.status === 'error',
                          'bg-gray-400 animate-pulse': !latencies[getNodeKey(node)]
                        }"
                      ></div>
                      <span :key="`latency-${getNodeKey(node)}`" class="text-xs font-semibold min-w-0" :class="{
                        'text-green-600 dark:text-green-400': latencies[getNodeKey(node)]?.status === 'good',
                        'text-yellow-600 dark:text-yellow-400': latencies[getNodeKey(node)]?.status === 'medium',
                        'text-red-600 dark:text-red-400': latencies[getNodeKey(node)]?.status === 'high' || latencies[getNodeKey(node)]?.status === 'error',
                        'text-gray-600 dark:text-gray-400': !latencies[getNodeKey(node)]
                      }">
                        <span v-if="!latencies[getNodeKey(node)]">Testing...</span>
                        <span v-else-if="latencies[getNodeKey(node)].status === 'error'">Offline</span>
                        <span v-else>{{ latencies[getNodeKey(node)].latency }}ms</span>
                      </span>
                    </div>
                    
                    <!-- Status Badge - 超小状态徽章 -->
                    <div v-if="latencies[getNodeKey(node)]" :key="`status-${getNodeKey(node)}`" class="text-xs font-medium px-1.5 py-0.5 rounded flex-shrink-0" :class="{
                      'bg-green-100 text-green-700 dark:bg-green-900/50 dark:text-green-400': latencies[getNodeKey(node)].status === 'good',
                      'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/50 dark:text-yellow-400': latencies[getNodeKey(node)].status === 'medium',
                      'bg-red-100 text-red-700 dark:bg-red-900/50 dark:text-red-400': latencies[getNodeKey(node)].status === 'high',
                      'bg-gray-100 text-gray-700 dark:bg-gray-900/50 dark:text-gray-400': latencies[getNodeKey(node)].status === 'error'
                    }">
                      {{ getStatusText(latencies[getNodeKey(node)]?.status) }}
                    </div>
                  </div>

                  <!-- Bottom section - 超紧凑按钮区域 -->
                  <div class="flex items-center justify-center mt-auto pt-1">
                    <!-- Ping Button - 超小按钮 -->
                    <button
                      @click.stop.prevent="pingSingleNode(node)"
                      :disabled="pingStates[getNodeKey(node)]?.isPinging"
                      class="inline-flex items-center px-2 py-1.5 rounded text-xs font-medium transition-all duration-200 w-full justify-center"
                      :class="pingStates[getNodeKey(node)]?.isPinging 
                        ? 'bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400 cursor-not-allowed'
                        : 'bg-primary-50 hover:bg-primary-100 text-primary-700 dark:bg-primary-900/30 dark:hover:bg-primary-900/50 dark:text-primary-400'"
                    >
                      <svg 
                        v-if="pingStates[getNodeKey(node)]?.isPinging" 
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
                      <span>{{ pingStates[getNodeKey(node)]?.isPinging ? 'Testing...' : 'Test' }}</span>
                    </button>
                  </div>
                </div>
              </div>
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
import { useNodesStore } from '@/stores/nodes'
import { storeToRefs } from 'pinia'

const nodesStore = useNodesStore()
const { 
  nodes, 
  selectedNode, 
  currentNode, 
  latencies, 
  loading, 
  pingStates 
} = storeToRefs(nodesStore)

const currentPage = ref(0)
const windowWidth = ref(typeof window !== 'undefined' ? window.innerWidth : 1024)

let latencyInterval = null

// Use store methods
const { 
  getNodeKey, 
  isCurrentNode, 
  getStatusText, 
  fetchNodes, 
  testAllLatencies, 
  pingSingleNode,
  selectNode 
} = nodesStore

// 监听窗口大小变化
const handleResize = () => {
  windowWidth.value = window.innerWidth
  // 如果当前页超出了新的总页数，回到第一页
  if (currentPage.value >= totalPages.value) {
    currentPage.value = 0
  }
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
