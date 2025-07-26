<script setup>
import { computed, onMounted, ref } from 'vue'
import { list as langList, setI18nLanguage, loadLocaleMessages, autoLang } from './config/lang.js'
import { useAppStore } from './stores/app'
import LoadingCard from '@/components/Loading.vue'
import InfoCard from '@/components/Information.vue'
import SpeedtestCard from '@/components/Speedtest.vue'
import UtilitiesCard from '@/components/Utilities.vue'
import TrafficCard from '@/components/TrafficDisplay.vue'
import ThemeToggle from '@/components/ThemeToggle.vue'
import LanguageSelector from '@/components/LanguageSelector.vue'

const currentLangCode = ref('en-US')
const isDark = ref(false)
const appStore = useAppStore()

const currentLang = computed(() => {
  for (const lang of langList) {
    if (lang.value === currentLangCode.value) {
      return lang
    }
  }
  return null
})

const handleLangChange = async (newLang) => {
  currentLangCode.value = newLang
  await loadLocaleMessages(currentLangCode.value)
  setI18nLanguage(currentLangCode.value)
}

const toggleTheme = () => {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
}

onMounted(async () => {
  const langCode = await autoLang()
  currentLangCode.value = langCode
  
  // Check system theme preference
  if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    isDark.value = true
    document.documentElement.classList.add('dark')
  }
})
</script>

<template>
  <div class="min-h-screen bg-gradient-to-br from-primary-50 via-white to-primary-100 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 transition-all duration-500">
    <!-- Enhanced floating decorative elements -->
    <div class="fixed inset-0 overflow-hidden pointer-events-none">
      <div class="absolute -top-40 -right-40 w-96 h-96 bg-gradient-to-r from-primary-200/40 to-blue-300/30 dark:from-primary-800/20 dark:to-blue-900/10 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse-slow"></div>
      <div class="absolute -bottom-40 -left-40 w-96 h-96 bg-gradient-to-r from-blue-200/40 to-primary-300/30 dark:from-blue-800/20 dark:to-primary-900/10 rounded-full mix-blend-multiply filter blur-3xl opacity-70 animate-pulse-slow" style="animation-delay: 2s;"></div>
      <div class="absolute top-1/3 right-1/4 w-64 h-64 bg-gradient-to-r from-primary-100/30 to-sky-200/20 dark:from-primary-900/10 dark:to-sky-900/5 rounded-full mix-blend-multiply filter blur-2xl opacity-50 animate-pulse-slow" style="animation-delay: 4s;"></div>
      <div class="absolute bottom-1/3 left-1/4 w-80 h-80 bg-gradient-to-r from-sky-100/30 to-primary-200/20 dark:from-sky-900/10 dark:to-primary-900/5 rounded-full mix-blend-multiply filter blur-2xl opacity-40 animate-pulse-slow" style="animation-delay: 6s;"></div>
    </div>

    <!-- Main container -->
    <div class="relative z-10 min-h-screen">
      <!-- Header -->
      <header class="pt-12 pb-8 px-4">
        <div class="max-w-6xl mx-auto text-center">
          <!-- Logo/Icon -->
          <div class="inline-flex items-center justify-center w-20 h-20 mb-6 bg-gradient-to-br from-primary-500 to-primary-600 rounded-2xl shadow-lg shadow-primary-500/25 animate-scale-in">
            <svg class="w-10 h-10 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9"/>
            </svg>
          </div>

          <!-- Title and subtitle -->
          <div class="space-y-4 animate-fade-in">
            <h1 class="text-4xl md:text-5xl lg:text-6xl font-bold bg-gradient-to-r from-primary-600 via-primary-500 to-blue-600 bg-clip-text text-transparent tracking-tight">
              Network Diagnostic Tools
            </h1>
            <p class="text-xl md:text-2xl text-gray-600 dark:text-gray-300 font-medium max-w-3xl mx-auto">
              {{ appStore.config?.location || 'Professional Looking Glass Server' }}
            </p>
            
            <!-- Status indicator -->
            <div class="inline-flex items-center px-4 py-2 bg-white/70 dark:bg-gray-800/70 backdrop-blur-sm rounded-full border border-primary-200/50 dark:border-primary-700/50 shadow-lg">
              <div class="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Server Online</span>
            </div>
          </div>
        </div>
      </header>

      <!-- Main content area -->
      <main class="pb-20 px-4">
        <div class="max-w-7xl mx-auto space-y-10">
          <LoadingCard v-if="appStore.connecting" />
          <template v-else>
            <!-- Network Information Card -->
            <div class="animate-slide-up">
              <InfoCard />
            </div>
            
            <!-- Looking Glass Card -->
            <div class="animate-slide-up" style="animation-delay: 0.1s;">
              <UtilitiesCard />
            </div>
            
            <!-- Speed Test Card -->
            <div class="animate-slide-up" style="animation-delay: 0.2s;">
              <SpeedtestCard />
            </div>

            <!-- Traffic Display (if enabled) -->
            <div v-if="appStore.config.feature_iface_traffic" class="animate-slide-up" style="animation-delay: 0.3s;">
              <TrafficCard />
            </div>
          </template>
        </div>
      </main>

      <!-- Footer -->
      <footer class="pb-12 px-4">
        <div class="max-w-7xl mx-auto text-center">
          <div class="inline-flex items-center justify-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
            <span>Powered by</span>
            <a 
              href="https://github.com/X-Zero-L/als" 
              target="_blank"
              class="font-medium text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 transition-colors duration-200"
            >
              ALS - Another Looking Glass Server
            </a>
          </div>
        </div>
      </footer>
    </div>

    <!-- Controls in fixed position -->
    <div class="fixed top-6 right-6 z-50">
      <div class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-lg rounded-2xl shadow-2xl border border-primary-200/50 dark:border-primary-700/50 p-4 ring-1 ring-primary-100/20 dark:ring-primary-800/20">
        <div class="flex items-center space-x-4">
          <ThemeToggle :is-dark="isDark" @toggle="toggleTheme" />
          <div class="w-px h-6 bg-gray-300 dark:bg-gray-600"></div>
          <LanguageSelector 
            :current-lang="currentLangCode" 
            :lang-list="langList"
            @change="handleLangChange" 
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style>
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

html {
  scroll-behavior: smooth;
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

body {
  margin: 0;
  padding: 0;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Enhanced animations */
@keyframes fadeIn {
  0% { opacity: 0; transform: translateY(20px); }
  100% { opacity: 1; transform: translateY(0); }
}

@keyframes slideUp {
  0% { opacity: 0; transform: translateY(30px); }
  100% { opacity: 1; transform: translateY(0); }
}

@keyframes scaleIn {
  0% { opacity: 0; transform: scale(0.9); }
  100% { opacity: 1; transform: scale(1); }
}

@keyframes pulse-slow {
  0%, 100% { opacity: 0.4; }
  50% { opacity: 0.8; }
}

.animate-fade-in {
  animation: fadeIn 0.8s ease-out;
}

.animate-slide-up {
  animation: slideUp 0.6s ease-out both;
}

.animate-scale-in {
  animation: scaleIn 0.5s ease-out;
}

.animate-pulse-slow {
  animation: pulse-slow 4s ease-in-out infinite;
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: rgba(59, 130, 246, 0.3);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: rgba(59, 130, 246, 0.5);
}

.dark ::-webkit-scrollbar-thumb {
  background: rgba(147, 197, 253, 0.3);
}

.dark ::-webkit-scrollbar-thumb:hover {
  background: rgba(147, 197, 253, 0.5);
}
</style>