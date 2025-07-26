<script setup>
import { ref, computed } from 'vue'
import { useAppStore } from '@/stores/app'
import { DocumentArrowDownIcon, GlobeAltIcon } from '@heroicons/vue/24/outline'

const appStore = useAppStore()
const url = ref(new URL(location.href))

const shouldShowSeparateTests = computed(() => {
  return appStore.config.public_ipv4 && appStore.config.public_ipv6 && 
         (!appStore.config.filetest_follow_domain || !appStore.config.filetest_follow_domain.length)
})

const getFileUrl = (fileSize, ipVersion = null) => {
  const basePath = `/session/${appStore.sessionId}/speedtest/file/${fileSize}.test`
  
  if (!ipVersion) {
    return `.${basePath}`
  }
  
  const ip = ipVersion === 'ipv4' ? appStore.config.public_ipv4 : appStore.config.public_ipv6
  const formattedIp = ipVersion === 'ipv6' ? `[${ip}]` : ip
  
  return `${url.value.protocol}//${formattedIp}:${url.value.port}${basePath}`
}
</script>

<template>
  <div class="space-y-6">
    <div class="text-center">
      <DocumentArrowDownIcon class="w-12 h-12 text-emerald-500 mx-auto mb-4" />
      <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">
        {{ $t('file_speedtest') }}
      </h3>
      <p class="text-gray-600 dark:text-gray-400">
        Download test files to measure your connection speed
      </p>
    </div>

    <!-- Single test (when using domain or no separate IPs) -->
    <div v-if="!shouldShowSeparateTests" class="text-center">
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <a
          v-for="fileSize in appStore.config.speedtest_files"
          :key="fileSize"
          :href="getFileUrl(fileSize)"
          target="_blank"
          class="inline-flex items-center justify-center px-4 py-3 bg-gradient-to-r from-emerald-500 to-teal-600 text-white font-medium rounded-xl hover:from-emerald-600 hover:to-teal-700 transition-all duration-200 hover:scale-105 hover:shadow-lg"
        >
          {{ fileSize }}
        </a>
      </div>
    </div>

    <!-- Separate IPv4/IPv6 tests -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- IPv4 Test -->
      <div v-if="appStore.config.public_ipv4" class="bg-blue-50 dark:bg-blue-900/20 rounded-xl p-6 border border-blue-200 dark:border-blue-800">
        <div class="text-center mb-4">
          <div class="inline-flex items-center justify-center w-10 h-10 bg-blue-500 rounded-xl mb-2">
            <GlobeAltIcon class="w-5 h-5 text-white" />
          </div>
          <h4 class="text-lg font-semibold text-blue-900 dark:text-blue-100">
            {{ $t('file_ipv4_speedtest') }}
          </h4>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <a
            v-for="fileSize in appStore.config.speedtest_files"
            :key="`ipv4-${fileSize}`"
            :href="getFileUrl(fileSize, 'ipv4')"
            target="_blank"
            class="inline-flex items-center justify-center px-3 py-2 bg-blue-500 text-white text-sm font-medium rounded-lg hover:bg-blue-600 transition-colors duration-200"
          >
            {{ fileSize }}
          </a>
        </div>
      </div>

      <!-- IPv6 Test -->
      <div v-if="appStore.config.public_ipv6" class="bg-purple-50 dark:bg-purple-900/20 rounded-xl p-6 border border-purple-200 dark:border-purple-800">
        <div class="text-center mb-4">
          <div class="inline-flex items-center justify-center w-10 h-10 bg-purple-500 rounded-xl mb-2">
            <GlobeAltIcon class="w-5 h-5 text-white" />
          </div>
          <h4 class="text-lg font-semibold text-purple-900 dark:text-purple-100">
            {{ $t('file_ipv6_speedtest') }}
          </h4>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <a
            v-for="fileSize in appStore.config.speedtest_files"
            :key="`ipv6-${fileSize}`"
            :href="getFileUrl(fileSize, 'ipv6')"
            target="_blank"
            class="inline-flex items-center justify-center px-3 py-2 bg-purple-500 text-white text-sm font-medium rounded-lg hover:bg-purple-600 transition-colors duration-200"
          >
            {{ fileSize }}
          </a>
        </div>
      </div>
    </div>
  </div>
</template>
