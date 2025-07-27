<script setup>
import { ref, onMounted } from 'vue'
import { useAppStore } from '@/stores/app'
import { useI18n } from 'vue-i18n'
import Copyable from './Copy.vue'
import Markdown from 'vue3-markdown-it'

const appStore = useAppStore()
const { t } = useI18n({ useScope: 'global' })

const copyToClipboard = async (text, buttonRef = null) => {
  try {
    await navigator.clipboard.writeText(text)
    
    // 显示复制成功的反馈
    if (buttonRef) {
      // 添加点击动画
      buttonRef.style.transform = 'scale(0.9)'
      buttonRef.style.transition = 'all 0.15s ease'
      
      setTimeout(() => {
        buttonRef.style.transform = 'scale(1)'
        buttonRef.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)'
      }, 150)

      const originalHTML = buttonRef.innerHTML
      const originalClass = buttonRef.className
      
      // 成功状态样式和图标
      buttonRef.innerHTML = '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>'
      buttonRef.className = originalClass.replace(/bg-primary-\d+/g, 'bg-green-500').replace(/hover:bg-primary-\d+/g, 'hover:bg-green-600').replace(/text-primary-\d+/g, 'text-white')
      buttonRef.style.transform = 'scale(1.1)'
      buttonRef.style.boxShadow = '0 4px 12px rgba(34, 197, 94, 0.4)'
      
      setTimeout(() => {
        buttonRef.style.transform = 'scale(1)'
        buttonRef.style.boxShadow = ''
        buttonRef.innerHTML = originalHTML
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
      const originalHTML = buttonRef.innerHTML
      buttonRef.style.transform = 'scale(0.9)'
      setTimeout(() => {
        buttonRef.style.transform = 'scale(1.1)'
        buttonRef.innerHTML = '<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>'
        setTimeout(() => {
          buttonRef.style.transform = 'scale(1)'
          buttonRef.innerHTML = originalHTML
        }, 2000)
      }, 100)
    }
  }
}
</script>

<template>
  <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden animate-slide-up">
    <div class="p-6">
      <div v-if="appStore.config" class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Location</label>
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
            <label class="block text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Server IPv4</label>
            <div class="flex">
              <input 
                type="text" 
                class="flex-1 bg-primary-50/50 dark:bg-gray-700 border border-primary-200 dark:border-gray-600 rounded-l-lg px-4 py-3 text-slate-800 dark:text-gray-100 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500" 
                :value="appStore.config.public_ipv4" 
                @focus="$event.target.select()" 
                readonly
              >
              <button 
                class="bg-primary-100 hover:bg-primary-200 dark:bg-gray-600 dark:hover:bg-gray-500 border border-l-0 border-primary-200 dark:border-gray-600 rounded-r-lg px-4 py-3 text-primary-600 dark:text-gray-100 transition-colors duration-200 min-w-[44px] flex items-center justify-center" 
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
            <label class="block text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Server IPv6</label>
            <div class="flex">
              <input 
                type="text" 
                class="flex-1 bg-primary-50/50 dark:bg-gray-700 border border-primary-200 dark:border-gray-600 rounded-l-lg px-4 py-3 text-slate-800 dark:text-gray-100 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500" 
                :value="appStore.config.public_ipv6" 
                @focus="$event.target.select()" 
                readonly
              >
              <button 
                class="bg-primary-100 hover:bg-primary-200 dark:bg-gray-600 dark:hover:bg-gray-500 border border-l-0 border-primary-200 dark:border-gray-600 rounded-r-lg px-4 py-3 text-primary-600 dark:text-gray-100 transition-colors duration-200 min-w-[44px] flex items-center justify-center" 
                @click="copyToClipboard(appStore.config.public_ipv6, $event.target)"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path>
                </svg>
              </button>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Your IP Address</label>
            <div class="flex">
              <input 
                type="text" 
                class="flex-1 bg-primary-100/70 dark:bg-gray-600 border border-primary-300 dark:border-gray-500 rounded-l-lg px-4 py-3 text-slate-800 dark:text-gray-100 font-mono text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500" 
                :value="appStore.config.my_ip" 
                @focus="$event.target.select()" 
                readonly
              >
              <button 
                class="bg-primary-200 hover:bg-primary-300 dark:bg-gray-500 dark:hover:bg-gray-400 border border-l-0 border-primary-300 dark:border-gray-500 rounded-r-lg px-4 py-3 text-primary-700 dark:text-gray-100 transition-colors duration-200 min-w-[44px] flex items-center justify-center" 
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
        class="mt-6 p-4 bg-primary-50/50 dark:bg-primary-900/20 rounded-lg border border-primary-200 dark:border-primary-700/30"
      >
        <div class="prose prose-primary max-w-none dark:prose-invert text-primary-700 dark:text-primary-300">
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