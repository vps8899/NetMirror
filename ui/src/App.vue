<script setup>
import { computed, onMounted, ref } from 'vue'
import { useMotion } from '@vueuse/motion'
import { list as langList, setI18nLanguage, loadLocaleMessages, autoLang } from './config/lang.js'
import { useAppStore } from './stores/app'
import LoadingCard from '@/components/Loading.vue'
import InfoCard from '@/components/Information.vue'
import SpeedtestCard from '@/components/Speedtest.vue'
import UtilitiesCard from '@/components/Utilities.vue'
import TrafficCard from '@/components/TrafficDisplay.vue'
import ThemeToggle from '@/components/ThemeToggle.vue'
import LanguageSelector from '@/components/LanguageSelector.vue'
import { WifiIcon } from 'lucide-vue-next'

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

// Motion setup
const headerRef = ref()
const { apply: applyHeader } = useMotion(headerRef, {
  initial: { opacity: 0, y: -30 },
  enter: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 100, damping: 15, delay: 100 } }
})

onMounted(async () => {
  const langCode = await autoLang()
  currentLangCode.value = langCode
  
  // Check system theme preference
  if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
    isDark.value = true
    document.documentElement.classList.add('dark')
  }
  
  applyHeader()
})
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-800 dark:text-gray-200 transition-colors duration-300">
    <!-- Animated Gradient Background -->
    <div class="animated-gradient absolute inset-0 -z-10"></div>
    
    <div class="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
      <!-- Header -->
      <header ref="headerRef" class="text-center mb-12 sm:mb-16">
        <div class="inline-flex items-center justify-center w-20 h-20 bg-white/20 dark:bg-black/20 backdrop-blur-lg rounded-3xl mb-6 shadow-lg border border-white/10">
          <WifiIcon class="w-10 h-10 text-primary-500" />
        </div>
        <h1 class="text-4xl sm:text-6xl font-bold bg-gradient-to-r from-gray-900 via-gray-700 to-gray-900 dark:from-white dark:via-gray-200 dark:to-white bg-clip-text text-transparent mb-4 tracking-tight">
          Looking Glass Server
        </h1>
        <p class="text-lg text-gray-600 dark:text-gray-400 max-w-3xl mx-auto">
          An elegant and powerful suite of network diagnostic tools. Real-time insights, at your fingertips.
        </p>
      </header>

      <!-- Controls -->
      <div class="sticky top-4 z-40 mb-8">
        <div class="max-w-md mx-auto bg-white/60 dark:bg-gray-800/60 backdrop-blur-xl rounded-2xl shadow-lg border border-white/20 dark:border-gray-700/50 p-2">
          <div class="flex justify-between items-center">
            <div class="flex items-center space-x-2">
              <ThemeToggle :is-dark="isDark" @toggle="toggleTheme" />
              <LanguageSelector 
                :current-lang="currentLangCode" 
                :lang-list="langList"
                @change="handleLangChange" 
              />
            </div>
            <div v-if="!appStore.connecting" class="text-xs font-medium text-gray-600 dark:text-gray-300 px-3 py-2 rounded-lg bg-white/50 dark:bg-gray-700/50">
              <span class="opacity-70">{{ $t('memory_usage') }}:</span> {{ appStore.memoryUsage }}
            </div>
          </div>
        </div>
      </div>

      <!-- Main Content -->
      <main class="space-y-8 sm:space-y-10">
        <LoadingCard v-if="appStore.connecting" />
        <template v-else>
          <InfoCard />
          <UtilitiesCard />
          <SpeedtestCard />
          <TrafficCard v-if="appStore.config.feature_iface_traffic" />
        </template>
      </main>

      <!-- Footer -->
      <footer class="mt-16 sm:mt-24 text-center">
        <div class="inline-flex items-center justify-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
          <span>Powered by</span>
          <a 
            href="https://github.com/wikihost-opensource/als" 
            target="_blank"
            class="font-medium text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 transition-colors duration-200"
          >
            WIKIHOST Opensource - ALS
          </a>
        </div>
      </footer>
    </div>
  </div>
</template>

<style>
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

html {
  scroll-behavior: smooth;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

@keyframes gradient-animation {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.animated-gradient {
  background: linear-gradient(-45deg, #e0f2fe, #d1fae5, #fef3c7, #fee2e2);
  background-size: 400% 400%;
  animation: gradient-animation 15s ease infinite;
}

.dark .animated-gradient {
  background: linear-gradient(-45deg, #0c4a6e, #064e3b, #78350f, #7f1d1d);
  background-size: 400% 400%;
  animation: gradient-animation 15s ease infinite;
  opacity: 0.3;
}
</style>
