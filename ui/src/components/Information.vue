<script setup>
import { ref, onMounted } from 'vue'
import { useAppStore } from '@/stores/app'
import { useI18n } from 'vue-i18n'
import Copyable from './Copy.vue'
import Markdown from 'vue3-markdown-it'

const appStore = useAppStore()
const { t } = useI18n({ useScope: 'global' })

const copyToClipboard = async (text, button) => {
  try {
    await navigator.clipboard.writeText(text)
    // Visual feedback could be added here
  } catch (err) {
    // Fallback for older browsers
    const textArea = document.createElement('textarea')
    textArea.value = text
    document.body.appendChild(textArea)
    textArea.select()
    document.execCommand('copy')
    document.body.removeChild(textArea)
  }
}
</script>

<template>
  <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden animate-slide-up">
    <div class="bg-gradient-to-r from-primary-600 to-primary-700 px-6 py-4">
      <h2 class="text-xl font-semibold text-white flex items-center">
        <svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9"></path>
        </svg>
        Network Information
      </h2>
    </div>
    <div class="p-6">
      <div v-if="appStore.config" class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-600 mb-2">Location</label>
            <div class="flex">
              <input 
                type="text" 
                class="flex-1 bg-primary-50/50 dark:bg-gray-700 border border-primary-200 dark:border-gray-600 rounded-l-lg px-4 py-3 text-slate-800 dark:text-gray-100 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500" 
                :value="appStore.config.location" 
                @focus="$event.target.select()" 
                readonly
              >
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-600 mb-2">Server IPv4</label>
            <div class="flex">
              <input 
                type="text" 
                class="flex-1 bg-gray-50 border border-gray-300 rounded-l-lg px-4 py-3 text-slate-800 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-slate-500" 
                :value="appStore.config.public_ipv4" 
                @focus="$event.target.select()" 
                readonly
              >
              <button 
                class="bg-gray-100 hover:bg-gray-200 border border-l-0 border-gray-300 rounded-r-lg px-4 py-3 text-gray-600 transition-colors duration-200 min-w-[44px] flex items-center justify-center" 
                @click="copyToClipboard(appStore.config.public_ipv4, $event.target)"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                </svg>
              </button>
            </div>
          </div>
        </div>
        <div class="space-y-4">
          <div v-if="appStore.config.public_ipv6">
            <label class="block text-sm font-medium text-gray-600 mb-2">Server IPv6</label>
            <div class="flex">
              <input 
                type="text" 
                class="flex-1 bg-gray-50 border border-gray-300 rounded-l-lg px-4 py-3 text-slate-800 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-slate-500" 
                :value="appStore.config.public_ipv6" 
                @focus="$event.target.select()" 
                readonly
              >
              <button 
                class="bg-gray-100 hover:bg-gray-200 border border-l-0 border-gray-300 rounded-r-lg px-4 py-3 text-gray-600 transition-colors duration-200 min-w-[44px] flex items-center justify-center" 
                @click="copyToClipboard(appStore.config.public_ipv6, $event.target)"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                </svg>
              </button>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-600 mb-2">Your IP Address</label>
            <div class="flex">
              <input 
                type="text" 
                class="flex-1 bg-blue-50 border border-blue-200 rounded-l-lg px-4 py-3 text-slate-800 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-blue-500" 
                :value="appStore.config.my_ip" 
                @focus="$event.target.select()" 
                readonly
              >
              <button 
                class="bg-blue-100 hover:bg-blue-200 border border-l-0 border-blue-200 rounded-r-lg px-4 py-3 text-blue-600 transition-colors duration-200 min-w-[44px] flex items-center justify-center" 
                @click="copyToClipboard(appStore.config.my_ip, $event.target)"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Sponsor Message -->
      <div 
        v-if="appStore.config?.sponsor_message?.length > 0"
        class="mt-6 p-4 bg-amber-50 rounded-lg border border-amber-200"
      >
        <div class="prose prose-amber max-w-none">
          <Markdown :source="appStore.config.sponsor_message" />
        </div>
      </div>
    </div>
  </div>
</template>

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
</style>