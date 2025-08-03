<template>
  <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden">
    <div class="p-4 border-b border-primary-200/30 dark:border-primary-700/30">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">Select Node</h3>
      <p class="text-sm text-gray-600 dark:text-gray-400">Choose which node to run diagnostics on</p>
    </div>
    
    <div class="p-4">
      <!-- Current Selection Display -->
      <div v-if="selectedNode" class="mb-4 p-3 bg-primary-50 dark:bg-primary-900/20 rounded-lg border border-primary-200 dark:border-primary-700">
        <div class="flex items-center justify-between">
          <div>
            <h4 class="font-medium text-primary-800 dark:text-primary-300">{{ selectedNode.name }}</h4>
            <p class="text-sm text-primary-600 dark:text-primary-400">{{ selectedNode.location }}</p>
          </div>
          <div class="flex items-center space-x-2">
            <div v-if="isCurrentNode(selectedNode)" class="px-2 py-1 bg-blue-100 dark:bg-blue-900/50 text-blue-800 dark:text-blue-300 text-xs rounded">
              Current
            </div>
            <div v-if="latencies[getNodeKey(selectedNode)]" class="px-2 py-1 text-xs rounded" :class="{
              'bg-green-100 text-green-800 dark:bg-green-900/50 dark:text-green-300': latencies[getNodeKey(selectedNode)].status === 'good',
              'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-300': latencies[getNodeKey(selectedNode)].status === 'medium',
              'bg-red-100 text-red-800 dark:bg-red-900/50 dark:text-red-300': latencies[getNodeKey(selectedNode)].status === 'high' || latencies[getNodeKey(selectedNode)].status === 'error'
            }">
              <span v-if="latencies[getNodeKey(selectedNode)].status === 'error'">Offline</span>
              <span v-else>{{ latencies[getNodeKey(selectedNode)].latency }}ms</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Node Selection Dropdown -->
      <div class="relative">
        <button
          ref="buttonRef"
          @click="toggleDropdown"
          class="w-full flex items-center justify-between px-4 py-3 bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg hover:border-primary-500 focus:border-primary-500 focus:ring-2 focus:ring-primary-500/20 transition-colors"
        >
          <span class="text-gray-900 dark:text-gray-100">
            {{ selectedNode ? `${selectedNode.name} (${selectedNode.location})` : 'Select a node...' }}
          </span>
          <svg 
            class="w-5 h-5 text-gray-400 transition-transform" 
            :class="{ 'rotate-180': showDropdown }"
            fill="none" 
            stroke="currentColor" 
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
          </svg>
        </button>

        <!-- Dropdown Menu -->
        <Teleport to="body">
          <transition
            enter-active-class="transition duration-200 ease-out"
            enter-from-class="opacity-0 scale-95"
            enter-to-class="opacity-100 scale-100"
            leave-active-class="transition duration-150 ease-in"
            leave-from-class="opacity-100 scale-100"
            leave-to-class="opacity-0 scale-95"
          >
            <div 
              v-if="showDropdown" 
              ref="dropdownRef"
              class="fixed z-[9999] bg-white dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg shadow-xl max-h-60 overflow-y-auto min-w-80"
              :style="dropdownStyle"
            >
              <button
                v-for="node in availableNodes"
                :key="node.url"
                @click="selectNodeAndClose(node)"
                class="w-full px-4 py-3 text-left hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors border-b border-gray-100 dark:border-gray-600 last:border-b-0"
                :class="{ 'bg-primary-50 dark:bg-primary-900/20': selectedNode && selectedNode.url === node.url }"
              >
                <div class="flex items-center justify-between">
                  <div>
                    <div class="font-medium text-gray-900 dark:text-gray-100">{{ node.name }}</div>
                    <div class="text-sm text-gray-600 dark:text-gray-400">{{ node.location }}</div>
                  </div>
                  <div class="flex items-center space-x-2">
                    <div v-if="isCurrentNode(node)" class="px-2 py-1 bg-blue-100 dark:bg-blue-900/50 text-blue-800 dark:text-blue-300 text-xs rounded">
                      Current
                    </div>
                    <div v-if="latencies[getNodeKey(node)]" class="flex items-center space-x-1">
                      <div
                        class="w-2 h-2 rounded-full"
                        :class="{
                          'bg-green-500': latencies[getNodeKey(node)].status === 'good',
                          'bg-yellow-500': latencies[getNodeKey(node)].status === 'medium',
                          'bg-red-500': latencies[getNodeKey(node)].status === 'high' || latencies[getNodeKey(node)].status === 'error'
                        }"
                      ></div>
                      <span class="text-xs text-gray-600 dark:text-gray-400">
                        <span v-if="latencies[getNodeKey(node)].status === 'error'">Offline</span>
                        <span v-else>{{ latencies[getNodeKey(node)].latency }}ms</span>
                      </span>
                    </div>
                    <div v-else class="w-2 h-2 bg-gray-400 rounded-full animate-pulse"></div>
                  </div>
                </div>
              </button>
            </div>
          </transition>
        </Teleport>
      </div>

      <!-- Quick Actions -->
      <div class="mt-4 flex space-x-2">
        <button
          @click="refreshNodes"
          :disabled="loading"
          class="flex-1 inline-flex items-center justify-center px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
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
          Refresh
        </button>
        
        <button
          v-if="selectedNode"
          @click="testSelectedNode"
          :disabled="pingStates[getNodeKey(selectedNode)]?.isPinging"
          class="flex-1 inline-flex items-center justify-center px-3 py-2 rounded-lg text-sm font-medium transition-all duration-200"
          :class="pingStates[getNodeKey(selectedNode)]?.isPinging
            ? 'bg-gray-100 text-gray-500 dark:bg-gray-700 dark:text-gray-400 cursor-not-allowed'
            : 'bg-green-50 hover:bg-green-100 text-green-700 dark:bg-green-900/30 dark:hover:bg-green-900/50 dark:text-green-400'"
        >
          <svg 
            v-if="pingStates[getNodeKey(selectedNode)]?.isPinging" 
            class="w-4 h-4 mr-2 animate-spin" 
            fill="none" 
            stroke="currentColor" 
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
          </svg>
          <svg 
            v-else
            class="w-4 h-4 mr-2" 
            fill="currentColor" 
            viewBox="0 0 24 24"
          >
            <path d="M13 10V3L4 14h7v7l9-11h-7z"/>
          </svg>
          Test
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted, onUnmounted } from 'vue'
import { useNodesStore } from '@/stores/nodes'
import { storeToRefs } from 'pinia'

const nodesStore = useNodesStore()
const { 
  availableNodes, 
  selectedNode, 
  latencies, 
  loading, 
  pingStates 
} = storeToRefs(nodesStore)

const { 
  getNodeKey, 
  isCurrentNode, 
  selectNode, 
  fetchNodes, 
  testAllLatencies, 
  pingSingleNode 
} = nodesStore

const showDropdown = ref(false)
const dropdownRef = ref(null)
const buttonRef = ref(null)

// Calculate dropdown position
const dropdownStyle = computed(() => {
  if (!buttonRef.value || !showDropdown.value) return {}
  
  const buttonRect = buttonRef.value.getBoundingClientRect()
  const viewportHeight = window.innerHeight
  const dropdownHeight = 240 // max-h-60 = 240px
  
  // Check if there's enough space below
  const spaceBelow = viewportHeight - buttonRect.bottom
  const spaceAbove = buttonRect.top
  
  let top, maxHeight
  
  if (spaceBelow >= dropdownHeight || spaceBelow >= spaceAbove) {
    // Position below
    top = buttonRect.bottom + 8
    maxHeight = Math.min(dropdownHeight, spaceBelow - 16)
  } else {
    // Position above
    top = buttonRect.top - Math.min(dropdownHeight, spaceAbove - 16)
    maxHeight = Math.min(dropdownHeight, spaceAbove - 16)
  }
  
  return {
    position: 'fixed',
    top: `${top}px`,
    left: `${buttonRect.left}px`,
    width: `${buttonRect.width}px`,
    maxHeight: `${maxHeight}px`,
    zIndex: 9999
  }
})

const selectNodeAndClose = async (node) => {
  await selectNode(node)
  showDropdown.value = false
}

const toggleDropdown = () => {
  showDropdown.value = !showDropdown.value
}

// Handle click outside to close dropdown
const handleClickOutside = (event) => {
  if (
    showDropdown.value && 
    buttonRef.value && 
    dropdownRef.value &&
    !buttonRef.value.contains(event.target) &&
    !dropdownRef.value.contains(event.target)
  ) {
    showDropdown.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})

const refreshNodes = async () => {
  await testAllLatencies()
}

const testSelectedNode = async () => {
  if (selectedNode.value) {
    await pingSingleNode(selectedNode.value)
  }
}
</script>