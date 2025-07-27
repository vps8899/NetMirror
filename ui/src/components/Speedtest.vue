<script setup>
import { ref, onMounted, computed } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import FileSpeedtest from '@/components/Speedtest/FileSpeedtest.vue'
import Librespeed from '@/components/Speedtest/Librespeed.vue'

const appStore = useAppStore()
const cardRef = ref()

const availableTests = computed(() => {
  const tests = []
  if (appStore.config.feature_librespeed) {
    tests.push({ id: 'librespeed', name: 'Librespeed' })
  }
  if (appStore.config.feature_filespeedtest) {
    tests.push({ id: 'filespeedtest', name: 'File-based Test' })
  }
  return tests
})

const activeTest = ref(availableTests.value.length > 0 ? availableTests.value[0].id : null)

const { apply } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 500, delay: 400 } }
})

onMounted(() => {
  if (availableTests.value.length > 0) {
    apply()
  }
})
</script>

<template>
  <div 
    v-if="availableTests.length > 0"
    ref="cardRef" 
    class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden animate-slide-up"
  >
    <div class="p-6 space-y-6">
      <!-- Sub-tabs for speed tests -->
      <div v-if="availableTests.length > 1" class="flex justify-center">
        <div class="bg-primary-100/50 dark:bg-gray-700/50 rounded-lg p-1 flex space-x-1">
          <button
            v-for="test in availableTests"
            :key="test.id"
            @click="activeTest = test.id"
            :class="[
              'px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200 focus:outline-none',
              activeTest === test.id
                ? 'bg-primary-600 text-white shadow-lg'
                : 'text-gray-600 dark:text-gray-300 hover:bg-primary-50 dark:hover:bg-gray-600/50 hover:text-primary-700 dark:hover:text-white'
            ]"
          >
            {{ test.name }}
          </button>
        </div>
      </div>

      <!-- Conditionally rendered speed test components -->
      <div>
        <Librespeed v-if="activeTest === 'librespeed'" />
        <FileSpeedtest v-if="activeTest === 'filespeedtest'" />
      </div>
    </div>
  </div>
</template>
