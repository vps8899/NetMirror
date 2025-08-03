<script setup>
import { ref, computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { useNodesStore } from '@/stores/nodes'
import { useNodeTool } from '@/composables/useNodeTool'
import { DocumentArrowDownIcon, ClipboardDocumentIcon, CommandLineIcon } from '@heroicons/vue/24/outline'

const appStore = useAppStore()
const nodesStore = useNodesStore()

const {
  selectedNode,
  selectedNodeName,
  selectedNodeLocation,
  hasSelectedNode
} = useNodeTool()

// 获取当前配置 - 使用节点的配置
const currentConfig = computed(() => {
  if (selectedNode.value && selectedNode.value.config) {
    return selectedNode.value.config
  }
  return appStore.config
})

// 获取当前会话ID
const currentSessionId = computed(() => {
  if (selectedNode.value) {
    return nodesStore.selectedNodeSession
  }
  return appStore.sessionId
})

// 获取基础URL
const baseUrl = computed(() => {
  if (selectedNode.value) {
    return selectedNode.value.url
  }
  return ''
})

const url = ref(new URL(location.href))

const shouldShowSeparateTests = computed(() => {
  return currentConfig.value.public_ipv4 && currentConfig.value.public_ipv6 && 
         (!currentConfig.value.filetest_follow_domain || !currentConfig.value.filetest_follow_domain.length)
})

const getFileUrl = (fileSize, ipVersion = null) => {
  const basePath = `/session/${currentSessionId.value}/speedtest/file/${fileSize}.test`
  
  if (!ipVersion) {
    // 如果选择了节点，使用节点的URL；否则使用相对路径
    return baseUrl.value ? `${baseUrl.value}${basePath}` : `.${basePath}`
  }
  
  const ip = ipVersion === 'ipv4' ? currentConfig.value.public_ipv4 : currentConfig.value.public_ipv6
  const formattedIp = ipVersion === 'ipv6' ? `[${ip}]` : ip
  
  // 使用节点的协议，如果没有选择节点则使用当前页面的协议
  const protocol = baseUrl.value ? new URL(baseUrl.value).protocol : url.value.protocol
  const port = baseUrl.value ? new URL(baseUrl.value).port || (protocol === 'https:' ? '443' : '80') : url.value.port
  
  return `${protocol}//${formattedIp}:${port}${basePath}`
}

const getFullUrl = (fileSize, ipVersion = null) => {
  const relativePath = getFileUrl(fileSize, ipVersion)
  if (relativePath.startsWith('./')) {
    return `${window.location.origin}${relativePath.substring(1)}`
  }
  return relativePath
}

const copyToClipboard = async (text, buttonRef = null) => {
  try {
    await navigator.clipboard.writeText(text)
    
    // 显示复制成功的反馈
    if (buttonRef) {
      // 添加点击动画
      buttonRef.style.transform = 'scale(0.95)'
      buttonRef.style.transition = 'all 0.15s ease'
      
      setTimeout(() => {
        buttonRef.style.transform = 'scale(1)'
        buttonRef.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
      }, 150)

      const originalText = buttonRef.textContent
      const originalClass = buttonRef.className
      
      // 成功状态样式
      buttonRef.textContent = '✓ Copied!'
      buttonRef.className = originalClass.replace(/bg-gray-\d+/g, 'bg-green-500').replace(/hover:bg-gray-\d+/g, 'hover:bg-green-600').replace(/text-gray-\d+/g, 'text-white')
      buttonRef.style.transform = 'scale(1.05)'
      buttonRef.style.boxShadow = '0 4px 12px rgba(34, 197, 94, 0.4)'
      
      setTimeout(() => {
        buttonRef.style.transform = 'scale(1)'
        buttonRef.style.boxShadow = ''
        buttonRef.textContent = originalText
        buttonRef.className = originalClass
        buttonRef.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
      }, 2000)
    }
  } catch (err) {
    // Fallback for older browsers
    const textArea = document.createElement('textarea')
    textArea.value = text
    document.body.appendChild(textArea)
    textArea.select()
    document.execCommand('copy')
    document.body.removeChild(textArea)
    
    if (buttonRef) {
      const originalText = buttonRef.textContent
      buttonRef.style.transform = 'scale(0.95)'
      setTimeout(() => {
        buttonRef.style.transform = 'scale(1.05)'
        buttonRef.textContent = '✓ Copied!'
        setTimeout(() => {
          buttonRef.style.transform = 'scale(1)'
          buttonRef.textContent = originalText
        }, 2000)
      }, 100)
    }
  }
}

const getCurlCommand = (fileSize, ipVersion = null) => {
  const url = getFullUrl(fileSize, ipVersion)
  return `curl -O "${url}"`
}

const getWgetCommand = (fileSize, ipVersion = null) => {
  const url = getFullUrl(fileSize, ipVersion)
  return `wget "${url}"`
}
</script>

<template>
  <div class="space-y-8">
    <!-- Single test (when using domain or no separate IPs) -->
    <div v-if="!shouldShowSeparateTests">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="fileSize in currentConfig.speedtest_files"
          :key="fileSize"
          class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-6 transition-all duration-300 hover:shadow-xl hover:border-primary-300/50 dark:hover:border-primary-600/50"
        >
          <!-- File size header -->
          <div class="text-center mb-6">
            <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl mb-3 shadow-lg">
              <DocumentArrowDownIcon class="w-8 h-8 text-white" />
            </div>
            <h4 class="text-2xl font-bold text-gray-900 dark:text-gray-100">{{ fileSize }}</h4>
            <p class="text-sm text-gray-500 dark:text-gray-400">Test File</p>
          </div>

          <!-- Download buttons -->
          <div class="space-y-3">
            <!-- Main browser download button -->
            <a
              :href="getFileUrl(fileSize)"
              target="_blank"
              class="w-full inline-flex items-center justify-center px-4 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white font-medium rounded-lg hover:from-primary-700 hover:to-primary-800 transition-all duration-200 hover:scale-105 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
            >
              <DocumentArrowDownIcon class="w-5 h-5 mr-2" />
              Browser Download
            </a>

            <!-- Command line options -->
            <div class="grid grid-cols-2 gap-2">
              <button
                @click="copyToClipboard(getCurlCommand(fileSize), $event.target)"
                class="inline-flex items-center justify-center px-3 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 text-sm font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                title="Copy curl command"
              >
                <CommandLineIcon class="w-4 h-4 mr-1" />
                curl
              </button>
              <button
                @click="copyToClipboard(getWgetCommand(fileSize), $event.target)"
                class="inline-flex items-center justify-center px-3 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 text-sm font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                title="Copy wget command"
              >
                <ClipboardDocumentIcon class="w-4 h-4 mr-1" />
                wget
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Separate IPv4/IPv6 tests -->
    <div v-else class="space-y-8">
      <!-- IPv4 Test -->
      <div v-if="currentConfig.public_ipv4">
        <div class="text-center mb-6">
          <h4 class="text-lg font-semibold text-primary-700 dark:text-primary-300 mb-2">IPv4 Speed Test</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400">{{ currentConfig.public_ipv4 }}</p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="fileSize in currentConfig.speedtest_files"
            :key="`ipv4-${fileSize}`"
            class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-6 transition-all duration-300 hover:shadow-xl hover:border-primary-300/50 dark:hover:border-primary-600/50"
          >
            <!-- File size header -->
            <div class="text-center mb-6">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl mb-3 shadow-lg">
                <DocumentArrowDownIcon class="w-8 h-8 text-white" />
              </div>
              <h4 class="text-2xl font-bold text-gray-900 dark:text-gray-100">{{ fileSize }}</h4>
              <p class="text-sm text-gray-500 dark:text-gray-400">IPv4 Test</p>
            </div>

            <!-- Download buttons -->
            <div class="space-y-3">
              <!-- Main browser download button -->
              <a
                :href="getFileUrl(fileSize, 'ipv4')"
                target="_blank"
                class="w-full inline-flex items-center justify-center px-4 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white font-medium rounded-lg hover:from-primary-700 hover:to-primary-800 transition-all duration-200 hover:scale-105 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              >
                <DocumentArrowDownIcon class="w-5 h-5 mr-2" />
                Browser Download
              </a>

              <!-- Command line options -->
              <div class="grid grid-cols-2 gap-2">
                <button
                  @click="copyToClipboard(getCurlCommand(fileSize, 'ipv4'), $event.target)"
                  class="inline-flex items-center justify-center px-3 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 text-sm font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                  title="Copy curl command"
                >
                  <CommandLineIcon class="w-4 h-4 mr-1" />
                  curl
                </button>
                <button
                  @click="copyToClipboard(getWgetCommand(fileSize, 'ipv4'), $event.target)"
                  class="inline-flex items-center justify-center px-3 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 text-sm font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                  title="Copy wget command"
                >
                  <ClipboardDocumentIcon class="w-4 h-4 mr-1" />
                  wget
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- IPv6 Test -->
      <div v-if="currentConfig.public_ipv6">
        <div class="text-center mb-6">
          <h4 class="text-lg font-semibold text-primary-700 dark:text-primary-300 mb-2">IPv6 Speed Test</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400">{{ currentConfig.public_ipv6 }}</p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <div
            v-for="fileSize in currentConfig.speedtest_files"
            :key="`ipv6-${fileSize}`"
            class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-6 transition-all duration-300 hover:shadow-xl hover:border-primary-300/50 dark:hover:border-primary-600/50"
          >
            <!-- File size header -->
            <div class="text-center mb-6">
              <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl mb-3 shadow-lg">
                <DocumentArrowDownIcon class="w-8 h-8 text-white" />
              </div>
              <h4 class="text-2xl font-bold text-gray-900 dark:text-gray-100">{{ fileSize }}</h4>
              <p class="text-sm text-gray-500 dark:text-gray-400">IPv6 Test</p>
            </div>

            <!-- Download buttons -->
            <div class="space-y-3">
              <!-- Main browser download button -->
              <a
                :href="getFileUrl(fileSize, 'ipv6')"
                target="_blank"
                class="w-full inline-flex items-center justify-center px-4 py-3 bg-gradient-to-r from-primary-600 to-primary-700 text-white font-medium rounded-lg hover:from-primary-700 hover:to-primary-800 transition-all duration-200 hover:scale-105 hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
              >
                <DocumentArrowDownIcon class="w-5 h-5 mr-2" />
                Browser Download
              </a>

              <!-- Command line options -->
              <div class="grid grid-cols-2 gap-2">
                <button
                  @click="copyToClipboard(getCurlCommand(fileSize, 'ipv6'), $event.target)"
                  class="inline-flex items-center justify-center px-3 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 text-sm font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                  title="Copy curl command"
                >
                  <CommandLineIcon class="w-4 h-4 mr-1" />
                  curl
                </button>
                <button
                  @click="copyToClipboard(getWgetCommand(fileSize, 'ipv6'), $event.target)"
                  class="inline-flex items-center justify-center px-3 py-2 bg-gray-100 hover:bg-gray-200 dark:bg-gray-700 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 text-sm font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                  title="Copy wget command"
                >
                  <ClipboardDocumentIcon class="w-4 h-4 mr-1" />
                  wget
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
