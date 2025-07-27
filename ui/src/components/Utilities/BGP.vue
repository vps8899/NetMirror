<template>
  <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden animate-slide-up">
    <div class="p-6">
      <!-- BGP Info Header -->
      <div v-if="appStore.config" class="mb-6">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-xl font-bold text-gray-900 dark:text-white">BGP Network Topology</h2>
            <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
              {{ getBGPDescription() }}
            </p>
          </div>
          <div class="flex space-x-2">
            <button
              @click="bgpGraphType = 'combined'"
              :class="bgpGraphType === 'combined' 
                ? 'bg-primary-500 text-white shadow-primary-500/25' 
                : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'"
              class="px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 shadow-sm"
            >
              Combined
            </button>
            <button
              @click="bgpGraphType = 'ipv4'"
              :class="bgpGraphType === 'ipv4' 
                ? 'bg-primary-500 text-white shadow-primary-500/25' 
                : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'"
              class="px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 shadow-sm"
            >
              IPv4
            </button>
            <button
              @click="bgpGraphType = 'ipv6'"
              :class="bgpGraphType === 'ipv6' 
                ? 'bg-primary-500 text-white shadow-primary-500/25' 
                : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600'"
              class="px-4 py-2 rounded-lg text-sm font-medium transition-all duration-200 shadow-sm"
            >
              IPv6
            </button>
          </div>
        </div>
      </div>

      <!-- BGP Graph Display -->
      <div class="bg-white dark:bg-gray-800 rounded-xl p-6 min-h-[500px] flex items-center justify-center border border-gray-200 dark:border-gray-700">
        <!-- Loading State -->
        <div v-if="bgpGraphLoading" class="text-center">
          <div class="inline-block animate-spin rounded-full h-12 w-12 border-4 border-primary-500 border-t-transparent"></div>
          <p class="mt-4 text-lg text-gray-600 dark:text-gray-400">Loading BGP topology...</p>
          <p class="text-sm text-gray-500 dark:text-gray-500 mt-2">{{ currentGraphName }}</p>
        </div>

        <!-- Error State -->
        <div v-else-if="bgpGraphError" class="text-center text-red-600 dark:text-red-400">
          <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <p class="text-lg font-medium mb-2">Failed to load BGP topology</p>
          <p class="text-sm text-gray-500 mb-4">{{ bgpGraphUrl }}</p>
          <button 
            @click="loadBGPGraph"
            class="px-4 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors"
          >
            Retry
          </button>
        </div>

        <!-- No ASN State -->
        <div v-else-if="!appStore.config?.asn" class="text-center text-gray-500 dark:text-gray-400">
          <svg class="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path>
          </svg>
          <p class="text-lg font-medium mb-2">No ASN Information</p>
          <p class="text-sm">BGP topology requires ASN data to be available</p>
        </div>

        <!-- Success State -->
        <div v-else-if="bgpGraphContent" class="w-full flex justify-center">
          <div class="w-full max-w-full overflow-auto">
            <div 
              v-html="bgpGraphContent" 
              class="text-center bgp-graph-container"
            ></div>
          </div>
        </div>
      </div>

      <!-- Graph Info -->
      <div v-if="bgpGraphContent && appStore.config?.asn" class="mt-4 p-4 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg border border-primary-200 dark:border-primary-700/30">
        <div class="flex items-center justify-between text-sm">
          <div class="text-gray-600 dark:text-gray-400">
            <span class="font-medium">Current view:</span> {{ currentGraphName }}
          </div>
          <div class="text-gray-600 dark:text-gray-400">
            <span class="font-medium">ASN:</span> {{ appStore.config.asn }}
          </div>
          <a 
            :href="`https://bgpview.io/asn/${asnNumber}`" 
            target="_blank"
            class="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 font-medium flex items-center transition-colors"
          >
            View on BGPView
            <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path>
            </svg>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { useAppStore } from '@/stores/app'

const appStore = useAppStore()

// BGP Graph related
const bgpGraphType = ref('combined')
const bgpGraphContent = ref('')
const bgpGraphOriginalContent = ref('') // Store original content for theme switching
const bgpGraphLoading = ref(false)
const bgpGraphError = ref(false)

// Theme detection
const isDarkMode = computed(() => appStore.theme === 'dark')

// Computed properties
const asnNumber = computed(() => {
  return appStore.config?.asn ? appStore.config.asn.replace('AS', '') : null
})

const currentGraphName = computed(() => {
  switch (bgpGraphType.value) {
    case 'ipv4': return 'IPv4 BGP Topology'
    case 'ipv6': return 'IPv6 BGP Topology'
    case 'combined': return 'Combined BGP Topology'
    default: return 'BGP Topology'
  }
})

const bgpGraphUrl = computed(() => {
  if (!asnNumber.value) return null
  
  // Use backend proxy instead of direct BGPView access
  switch (bgpGraphType.value) {
    case 'ipv4':
      return `/bgp/graph/${asnNumber.value}/ipv4`
    case 'ipv6':
      return `/bgp/graph/${asnNumber.value}/ipv6`
    case 'combined':
      return `/bgp/graph/${asnNumber.value}/combined`
    default:
      return `/bgp/graph/${asnNumber.value}/combined`
  }
})

// Auto load graph when ASN becomes available
watch(() => appStore.config?.asn, (newAsn) => {
  if (newAsn && !bgpGraphContent.value) {
    loadBGPGraph()
  }
}, { immediate: true })

// Watch for graph type changes
watch(bgpGraphType, () => {
  if (bgpGraphUrl.value) {
    loadBGPGraph()
  }
})

// Watch for theme changes and reprocess existing content (no reload)
watch(() => appStore.theme, () => {
  if (bgpGraphOriginalContent.value && bgpGraphOriginalContent.value.includes('<svg')) {
    // Reprocess original SVG content for new theme
    if (isDarkMode.value) {
      bgpGraphContent.value = processSvgForDarkMode(bgpGraphOriginalContent.value)
    } else {
      // Use original content for light mode
      bgpGraphContent.value = bgpGraphOriginalContent.value
    }
  }
})

// Load BGP graph
const loadBGPGraph = async () => {
  if (!bgpGraphUrl.value) return
  
  bgpGraphLoading.value = true
  bgpGraphError.value = false
  bgpGraphContent.value = ''
  bgpGraphOriginalContent.value = ''
  
  console.log('Loading BGP graph from:', bgpGraphUrl.value)
  
  try {
    const response = await fetch(bgpGraphUrl.value)
    console.log('BGP graph response status:', response.status)
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`)
    }
    
    let svgContent = await response.text()
    console.log('BGP graph loaded, content length:', svgContent.length)
    
    if (svgContent.includes('<svg')) {
      // Store original content
      bgpGraphOriginalContent.value = svgContent
      
      // Apply theme processing if needed
      if (isDarkMode.value) {
        bgpGraphContent.value = processSvgForDarkMode(svgContent)
      } else {
        bgpGraphContent.value = svgContent
      }
    } else {
      throw new Error('Invalid SVG content')
    }
  } catch (error) {
    console.error('Failed to load BGP graph:', error)
    bgpGraphError.value = true
  } finally {
    bgpGraphLoading.value = false
  }
}

// 处理SVG以适应暗色模式
const processSvgForDarkMode = (svgContent) => {
  let processed = svgContent
    // 处理BGPView特有的颜色
    .replace(/fill="#2c94b3"/g, 'fill="#60a5fa"')     // BGPView蓝色文本 -> 更亮的蓝色
    .replace(/fill="#880000"/g, 'fill="#ef4444"')     // 深红色 -> 红色
    .replace(/fill="#000000"/g, 'fill="#ffffff"')     // 黑色 -> 白色
    .replace(/stroke="#000000"/g, 'stroke="#ffffff"') // 黑色线条 -> 白色
    
    // 处理背景
    .replace(/fill="#ffffff"/g, 'fill="#1f2937"')     // 白色背景 -> 深灰色
    .replace(/polygon fill="#ffffff"/g, 'polygon fill="#1f2937"') // 多边形背景
    
    // 添加暗色背景到SVG根元素
    .replace(/<svg([^>]*?)>/, '<svg$1 style="background-color: #1f2937; border-radius: 8px; padding: 10px;">')
  
  return processed
}

// Get BGP description for display
const getBGPDescription = () => {
  if (!appStore.config?.bgp && !appStore.config?.asn) {
    return 'Network topology visualization'
  }
  
  // If we have full BGP info, show it as is
  if (appStore.config.bgp) {
    return appStore.config.bgp
  }
  
  // If we only have ASN, show it
  return appStore.config.asn || 'Network topology visualization'
}

// Load graph on component mount if ASN is already available
onMounted(() => {
  if (appStore.config?.asn) {
    loadBGPGraph()
  }
})
</script>

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

/* BGP SVG 图表容器样式 */
.bgp-graph-container :deep(svg) {
  max-width: 100%;
  height: auto;
  margin: 0 auto;
  display: block;
}
</style>