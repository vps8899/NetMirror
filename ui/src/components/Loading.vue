<script setup>
import { ref, onMounted } from 'vue'
import { useMotion } from '@vueuse/motion'

const cardRef = ref()
const { apply } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 500 } }
})

onMounted(() => {
  apply()
})
</script>

<template>
  <div ref="cardRef" class="max-w-md mx-auto">
    <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl border border-gray-200 dark:border-gray-700 p-8">
      <div class="text-center">
        <div class="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-primary-500 to-primary-600 rounded-2xl mb-6">
          <div class="w-8 h-8 border-4 border-white border-t-transparent rounded-full animate-spin"></div>
        </div>
        <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Connecting...</h3>
        <p class="text-gray-600 dark:text-gray-400 mb-6">Establishing connection to the server</p>
        
        <!-- Progress bar -->
        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
          <div class="bg-gradient-to-r from-primary-500 to-primary-600 h-2 rounded-full animate-pulse" style="width: 100%"></div>
        </div>
      </div>
    </div>
  </div>
</template>
