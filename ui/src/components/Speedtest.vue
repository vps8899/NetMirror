<script setup>
import { ref, onMounted } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import FileSpeedtest from '@/components/Speedtest/FileSpeedtest.vue'
import Librespeed from '@/components/Speedtest/Librespeed.vue'
import { RocketLaunchIcon } from '@heroicons/vue/24/outline'

const appStore = useAppStore()
const cardRef = ref()
const { apply } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 500, delay: 400 } }
})

onMounted(() => {
  if (appStore.config?.feature_librespeed || appStore.config?.feature_filespeedtest) {
    apply()
  }
})
</script>

<template>
  <div 
    v-if="appStore.config?.feature_librespeed || appStore.config?.feature_filespeedtest"
    ref="cardRef" 
    class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden"
  >
    <div class="px-6 py-4 bg-gradient-to-r from-primary-600 to-primary-700">
      <h2 class="text-xl font-semibold text-white flex items-center">
        <RocketLaunchIcon class="w-6 h-6 mr-2" />
        {{ $t('server_speedtest') }}
      </h2>
    </div>
    
    <div class="p-6 space-y-8">
      <Librespeed v-if="appStore.config.feature_librespeed" />
      
      <div v-if="appStore.config.feature_filespeedtest && appStore.config.feature_librespeed" class="relative">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full border-t border-primary-200/30 dark:border-primary-700/30"></div>
        </div>
        <div class="relative flex justify-center">
          <span class="px-4 bg-white/90 dark:bg-gray-800/90 text-sm text-gray-500 dark:text-gray-400">or</span>
        </div>
      </div>
      
      <FileSpeedtest v-if="appStore.config.feature_filespeedtest" />
    </div>
  </div>
</template>
