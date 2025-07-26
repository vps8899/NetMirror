<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useAppStore } from '@/stores/app'
import { PlayIcon, StopIcon, ChartBarIcon } from '@heroicons/vue/24/outline'
import { markRaw } from 'vue'

const appStore = useAppStore()
const working = ref(false)
const output = ref('')
const host = ref('')
const inputRef = ref()
const outputRef = ref()

let abortController = markRaw(new AbortController())

const handleMTR6Message = (e) => {
  try {
    const data = JSON.parse(e.data)
    if (data.output) {
      output.value += data.output
    }
  } catch (error) {
    // If not JSON, treat as plain text
    output.value += e.data
  }
  
  // Auto scroll to bottom
  setTimeout(() => {
    const container = outputRef.value
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  }, 50)
}

onUnmounted(() => {
  stopMTR6()
})

const stopMTR6 = () => {
  appStore.source.removeEventListener('MTR6Output', handleMTR6Message)
  abortController.abort('Unmounted')
}

const runMTR6 = async () => {
  if (working.value) return stopMTR6()
  
  if (!host.value.trim()) {
    inputRef.value?.focus()
    return
  }
  
  abortController = new AbortController()
  output.value = ''
  working.value = true
  
  appStore.source.addEventListener('MTR6Output', handleMTR6Message)
  
  try {
    await appStore.requestMethod('mtr6', { ip: host.value }, abortController.signal)
  } catch (e) {
    console.error('MTR6 error:', e)
  }
  
  stopMTR6()
  working.value = false
}

onMounted(() => {
  inputRef.value?.focus()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Input Section -->
    <div class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="relative flex-1">
          <ChartBarIcon class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            ref="inputRef"
            v-model="host"
            :disabled="working"
            type="text"
            placeholder="Enter IPv6 address or domain name"
            class="w-full pl-10 pr-4 py-3 bg-transparent border-0 rounded-xl focus:ring-0 transition-all duration-200 disabled:opacity-50 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400"
            @keyup.enter="runMTR6"
          />
        </div>
        <button
          @click="runMTR6"
          :disabled="!host.trim()"
          class="inline-flex items-center justify-center px-6 py-3 rounded-xl font-medium transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
          :class="working 
            ? 'bg-red-500 hover:bg-red-600 text-white' 
            : 'bg-sky-500 hover:bg-sky-600 text-white hover:shadow-lg'"
        >
          <component :is="working ? StopIcon : PlayIcon" class="w-5 h-5 mr-2" />
          {{ working ? 'Stop' : 'Start MTR IPv6' }}
        </button>
      </div>
    </div>

    <!-- Results Section -->
    <div v-if="output" class="bg-gray-900 dark:bg-gray-950 rounded-xl border border-gray-700 overflow-hidden shadow-sm">
      <div 
        ref="outputRef"
        class="p-4 text-sm font-mono text-gray-100 overflow-x-auto max-h-[30rem] overflow-y-auto whitespace-pre"
      >{{ output }}</div>
    </div>

    <!-- Empty State -->
    <div v-else-if="!working" class="text-center py-12">
      <ChartBarIcon class="w-16 h-16 text-gray-400/50 dark:text-gray-500/50 mx-auto mb-4" />
      <h3 class="text-lg font-medium text-gray-700 dark:text-gray-300 mb-2">Ready to Run MTR IPv6</h3>
      <p class="text-gray-500 dark:text-gray-400">Enter an IPv6 address or domain name to analyze the network path.</p>
    </div>

    <!-- Loading State -->
    <div v-else class="text-center py-12">
      <div class="inline-flex items-center space-x-2">
        <svg class="animate-spin h-5 w-5 text-sky-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span class="text-gray-600 dark:text-gray-400">Running MTR IPv6 analysis...</span>
      </div>
    </div>
  </div>
</template>