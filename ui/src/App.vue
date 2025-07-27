<script setup>
import { computed, onMounted, ref } from 'vue'
import { list as langList, setI18nLanguage, loadLocaleMessages } from './config/lang.js'
import { useAppStore } from './stores/app'
import NodeListCard from '@/components/Utilities/NodeList.vue'
import LoadingCard from '@/components/Loading.vue'
import InfoCard from '@/components/Information.vue'
import SpeedtestCard from '@/components/Speedtest.vue'
import UtilitiesCard from '@/components/Utilities.vue'
import TrafficCard from '@/components/TrafficDisplay.vue'
import ThemeToggle from '@/components/ThemeToggle.vue'
import LanguageSelector from '@/components/LanguageSelector.vue'

const appStore = useAppStore()
const activeTab = ref('info')
const tabContainer = ref(null)
const tabNavigation = ref(null)
const showFab = ref(false)

// Use store theme and language
const isDark = computed(() => appStore.theme === 'dark')
const currentLangCode = computed(() => appStore.language)

const tabs = [
  { id: 'info', label: 'Network Information', icon: 'M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9' },
  { id: 'tools', label: 'Network Tools', icon: 'M15 12a3 3 0 11-6 0 3 3 0 016 0zM2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z' },
  { id: 'speedtest', label: 'Speed Test', icon: 'M13 10V3L4 14h7v7l9-11h-7z' },
  { id: 'traffic', label: 'Traffic Monitor', icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z' }
]

const filteredTabs = computed(() => {
  if (!appStore.config.feature_iface_traffic) {
    return tabs.filter(tab => tab.id !== 'traffic')
  }
  return tabs
})

const tabIndex = computed(() => {
  return filteredTabs.value.findIndex(tab => tab.id === activeTab.value)
})

const currentLang = computed(() => {
  for (const lang of langList) {
    if (lang.value === currentLangCode.value) {
      return lang
    }
  }
  return null
})

const handleLangChange = async (newLang) => {
  appStore.setLanguage(newLang)
  await loadLocaleMessages(newLang)
  setI18nLanguage(newLang)
}

const toggleTheme = () => {
  appStore.setTheme(appStore.theme === 'dark' ? 'light' : 'dark')
}

const changeTab = (tabId) => {
  activeTab.value = tabId
  // 延迟一下让动画开始，然后滚动到tab导航位置
  setTimeout(() => {
    if (tabNavigation.value) {
      const rect = tabNavigation.value.getBoundingClientRect()
      const scrollTop = window.pageYOffset + rect.top - 100 // 留100px的顶部空间
      window.scrollTo({
        top: scrollTop,
        behavior: 'smooth'
      })
    }
  }, 50)
}

const handleScroll = () => {
  if (window.scrollY > 200) {
    showFab.value = true
  } else {
    showFab.value = false
  }
}

const scrollToTop = () => {
  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  })
}

onMounted(async () => {
  // Initialize the app store and wait for session ID
  await appStore.initialize()
  
  // Load stored language
  await loadLocaleMessages(appStore.language)
  setI1-nLanguage(appStore.language)

  window.addEventListener('scroll', handleScroll)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
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
      <header class="pt-8 pb-6 px-4">
        <div class="max-w-6xl mx-auto text-center">
          <!-- Logo/Icon -->
          <div class="inline-flex items-center justify-center w-14 h-14 mb-4 bg-gradient-to-br from-primary-500 to-primary-600 rounded-xl shadow-lg shadow-primary-500/25 animate-scale-in">
            <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9v-9m0-9v9"/>
            </svg>
          </div>

          <!-- Title and subtitle -->
          <div class="space-y-3 animate-fade-in">
            <h1 class="text-2xl md:text-3xl lg:text-4xl font-bold bg-gradient-to-r from-primary-600 via-primary-500 to-blue-600 bg-clip-text text-transparent tracking-tight">
              Network Diagnostic Tools
            </h1>
            <p class="text-base md:text-lg text-gray-600 dark:text-gray-300 font-medium max-w-2xl mx-auto">
              {{ appStore.config?.location || 'Professional Looking Glass Server' }}
            </p>
            
            <!-- Status indicator -->
            <div class="inline-flex items-center px-3 py-1.5 bg-white/70 dark:bg-gray-800/70 backdrop-blur-sm rounded-full border border-primary-200/50 dark:border-primary-700/50 shadow-lg">
              <div class="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></div>
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Server Online</span>
            </div>
          </div>
        </div>
      </header>

      <!-- Main content area -->
      <main class="pb-16 px-4">
        <div class="max-w-7xl mx-auto space-y-6">
          <LoadingCard v-if="appStore.connecting" />
          <template v-else>
            <!-- Node List Card - Display at the top -->
            <div class="animate-slide-up">
              <NodeListCard />
            </div>
            
            <!-- Tab Navigation -->
            <div ref="tabNavigation" class="animate-slide-up" style="animation-delay: 0.1s;">
              <div class="bg-white/60 dark:bg-gray-800/60 backdrop-blur-lg rounded-2xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 p-2 inline-block">
                <div class="flex gap-2">
                  <button
                    v-for="tab in filteredTabs"
                    :key="tab.id"
                    @click="changeTab(tab.id)"
                    class="flex items-center space-x-2 px-4 py-2.5 rounded-xl font-medium transition-all duration-200 group"
                    :class="activeTab === tab.id 
                      ? 'bg-gradient-to-r from-primary-500 to-primary-600 text-white shadow-lg' 
                      : 'bg-white/50 dark:bg-gray-700/50 text-gray-700 dark:text-gray-300 hover:bg-white/80 dark:hover:bg-gray-700/80'"
                  >
                    <svg class="w-5 h-5 transition-transform duration-200" :class="activeTab === tab.id ? 'rotate-12' : 'group-hover:rotate-6'" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" :d="tab.icon"></path>
                    </svg>
                    <span>{{ tab.label }}</span>
                  </button>
                </div>
              </div>
            </div>
            
            <!-- Tab Content -->
            <div class="relative mt-6 overflow-hidden">
              <div 
                class="flex transition-transform duration-300 ease-out"
                :style="{ transform: `translateX(-${tabIndex * 100}%)` }"
              >
                <div 
                  v-for="(tab, index) in filteredTabs" 
                  :key="tab.id"
                  class="w-full flex-shrink-0"
                  :style="{ order: index }"
                >
                  <InfoCard v-if="tab.id === 'info'" />
                  <UtilitiesCard v-else-if="tab.id === 'tools'" />
                  <SpeedtestCard v-else-if="tab.id === 'speedtest'" />
                  <TrafficCard v-else-if="tab.id === 'traffic'" />
                </div>
              </div>
            </div>
          </template>
        </div>
      </main>

      <!-- Footer -->
      <footer class="pb-8 px-4">
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

    <!-- Floating Action Button Group -->
    <div class="fixed bottom-8 right-8 z-50">
      <transition
        enter-active-class="transition-all duration-300 ease-out"
        enter-from-class="opacity-0 translate-y-4"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition-all duration-200 ease-in"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 translate-y-4"
      >
        <div v-if="showFab" class="relative group flex flex-col items-center space-y-2">
          <!-- Action Buttons (hidden by default, shown on hover) -->
          <div class="absolute bottom-14 space-y-2 transition-all duration-300 opacity-0 group-hover:opacity-100 group-hover:-translate-y-2">
            <!-- Scroll to Top -->
            <button @click="scrollToTop" class="w-14 h-14 flex items-center justify-center bg-white dark:bg-gray-700 rounded-full shadow-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-all duration-200 transform hover:scale-110">
              <svg class="w-6 h-6 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 15l7-7 7 7"></path></svg>
            </button>
            <!-- Language Selector -->
            <div class="w-14 h-14 flex items-center justify-center bg-white dark:bg-gray-700 rounded-full shadow-lg">
              <LanguageSelector 
                :current-lang="currentLangCode" 
                :lang-list="langList"
                @change="handleLangChange" 
                :show-label="false"
              />
            </div>
            <!-- Theme Toggle -->
            <div class="w-14 h-14 flex items-center justify-center bg-white dark:bg-gray-700 rounded-full shadow-lg">
              <ThemeToggle :is-dark="isDark" @toggle="toggleTheme" />
            </div>
          </div>
          
          <!-- Main FAB -->
          <button class="w-16 h-16 bg-gradient-to-br from-primary-500 to-primary-600 text-white rounded-full shadow-2xl shadow-primary-500/30 flex items-center justify-center transform group-hover:rotate-90 transition-transform duration-300 focus:outline-none">
            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>
          </button>
        </div>
      </transition>
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

/* Enhanced glassmorphism/acrylic effect */
.glass-effect {
  background: rgba(255, 255, 255, 0.6);
  backdrop-filter: blur(12px) saturate(180%);
  -webkit-backdrop-filter: blur(12px) saturate(180%);
}

.dark .glass-effect {
  background: rgba(31, 41, 55, 0.6);
}

/* Tab transitions */
.tab-enter-active {
  transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

.tab-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.6, 1);
}

.tab-enter-from {
  opacity: 0;
  transform: translateY(20px);
}

.tab-leave-to {
  opacity: 0;
  transform: translateY(-20px);
}
</style>