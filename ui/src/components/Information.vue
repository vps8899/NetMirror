<script setup>
import { ref, onMounted } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { useI18n } from 'vue-i18n'
import Copyable from './Copy.vue'
import Markdown from 'vue3-markdown-it'
import { ServerIcon, GlobeAltIcon, ComputerDesktopIcon, HeartIcon } from '@heroicons/vue/24/outline'

const appStore = useAppStore()
const { t } = useI18n({ useScope: 'global' })

const cardRef = ref()
const sponsorRef = ref()

const { apply: applyCard } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 100, damping: 15, delay: 200 } }
})

const { apply: applySponsor } = useMotion(sponsorRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 100, damping: 15, delay: 400 } }
})

const configKeyMap = ref({
  location: { key: 'server_location', icon: GlobeAltIcon },
  my_ip: { key: 'my_address', icon: ComputerDesktopIcon },
  public_ipv4: { key: 'ipv4_address', icon: ServerIcon },
  public_ipv6: { key: 'ipv6_address', icon: ServerIcon }
})

onMounted(() => {
  applyCard()
  if (appStore.config?.sponsor_message?.length > 0) {
    applySponsor()
  }
})
</script>

<template>
  <div class="space-y-6">
    <!-- Main Info Card -->
    <div ref="cardRef" class="card-base">
      <div class="card-header bg-gradient-to-r from-primary-500 to-primary-600">
        <h2 class="text-xl font-semibold text-white flex items-center">
          <ServerIcon class="w-6 h-6 mr-3" />
          {{ $t('server_info') }}
        </h2>
      </div>
      
      <div class="p-6">
        <div v-if="appStore.config" class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <template v-for="(config, key) in configKeyMap" :key="key">
            <div v-if="appStore.config[key]" class="group">
              <div class="bg-white/50 dark:bg-gray-700/30 rounded-xl p-4 transition-all duration-300 border border-gray-200 dark:border-gray-700 hover:shadow-lg hover:border-primary-300 dark:hover:border-primary-500 hover:-translate-y-1">
                <div class="flex items-center mb-2">
                  <component :is="config.icon" class="w-5 h-5 text-primary-500 mr-3" />
                  <h3 class="text-sm font-medium text-gray-600 dark:text-gray-400">{{ $t(config.key) }}</h3>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-lg font-semibold text-gray-900 dark:text-white font-mono truncate">
                    {{ appStore.config[key] }}
                  </span>
                  <Copyable :value="appStore.config[key]" />
                </div>
              </div>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- Sponsor Message Card -->
    <div 
      v-if="appStore.config?.sponsor_message?.length > 0" 
      ref="sponsorRef"
      class="card-base"
    >
      <div class="card-header bg-gradient-to-r from-amber-500 to-orange-500">
        <h2 class="text-xl font-semibold text-white flex items-center">
          <HeartIcon class="w-6 h-6 mr-3" />
          {{ $t('sponsor_message') }}
        </h2>
      </div>
      
      <div class="p-6">
        <div class="prose prose-gray dark:prose-invert max-w-none">
          <Markdown :source="appStore.config.sponsor_message" />
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.prose a {
  @apply text-primary-600 hover:text-primary-700 dark:text-primary-400 dark:hover:text-primary-300 transition-colors duration-200;
}
</style>
