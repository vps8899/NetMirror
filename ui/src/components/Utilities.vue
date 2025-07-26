<script setup>
import { ref, computed, defineAsyncComponent, onMounted, h, shallowRef, toRaw } from 'vue'
import { storeToRefs } from 'pinia'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { 
  WifiIcon, 
  CommandLineIcon, 
  SignalIcon, 
  ServerIcon,
  XMarkIcon,
  ChevronRightIcon
} from '@heroicons/vue/24/outline'

const appStore = useAppStore()
const { config } = storeToRefs(appStore)

const cardRef = ref()
const toolComponent = shallowRef(null)
const currentTool = ref(null)
const toolComponentShow = computed({
  get() {
    return currentTool.value !== null
  },
  set(newValue) {
    if (!newValue) {
      currentTool.value = null
      toolComponent.value = null
    }
  }
})
const hasToolEnable = computed(() => {
  return tools.value.some(tool => tool.enable)
})

const tools = ref([
  {
    label: 'Ping',
    description: 'Test network connectivity',
    icon: SignalIcon,
    color: 'from-blue-500 to-sky-500',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Ping.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  },
  {
    label: 'IPerf3',
    description: 'Measure network bandwidth',
    icon: WifiIcon,
    color: 'from-green-500 to-emerald-500',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/IPerf3.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  },
  {
    label: 'Speedtest.net',
    description: 'Official Speedtest CLI',
    icon: ServerIcon,
    color: 'from-purple-500 to-violet-500',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/SpeedtestNet.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  },
  {
    label: 'Shell',
    description: 'Interactive command line',
    icon: CommandLineIcon,
    color: 'from-gray-600 to-gray-700',
    show: false,
    enable: false,
    componentNode: defineAsyncComponent({
      loader: () => import('./Utilities/Shell.vue'),
      delay: 200,
      loadingComponent: () => h('div', { class: 'flex items-center justify-center p-8' }, [
        h('div', { class: 'w-8 h-8 border-4 border-primary-500 border-t-transparent rounded-full animate-spin' })
      ])
    })
  }
])

const { apply: applyCard } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 100, damping: 15, delay: 300 } }
})

onMounted(() => {
  for (const tool of tools.value) {
    const configKey = 'feature_' + tool.label.toLowerCase().replace('.', '_dot_')
    tool.enable = config.value[configKey] ?? false
  }
  applyCard()
})

const openTool = (tool) => {
  currentTool.value = tool
  toolComponent.value = toRaw(tool.componentNode)
}

const closeTool = () => {
  toolComponentShow.value = false
}
</script>

<template>
  <div v-if="hasToolEnable" ref="cardRef" class="card-base">
    <div class="card-header bg-gradient-to-r from-indigo-500 to-purple-600">
      <h2 class="text-xl font-semibold text-white flex items-center">
        <CommandLineIcon class="w-6 h-6 mr-3" />
        {{ $t('network_tools') }}
      </h2>
    </div>
    
    <div class="p-6">
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <template v-for="tool in tools" :key="tool.label">
          <button
            v-if="tool.enable"
            @click="openTool(tool)"
            class="group relative overflow-hidden rounded-xl p-5 text-left bg-gray-50 dark:bg-gray-700/50 border border-gray-200 dark:border-gray-700 hover:border-transparent transition-all duration-300"
          >
            <div 
              class="absolute -inset-px rounded-xl opacity-0 group-hover:opacity-100 transition-opacity duration-300"
              :class="`bg-gradient-to-br ${tool.color}`"
            ></div>
            
            <div class="relative z-10 flex items-center space-x-4">
              <div 
                class="flex items-center justify-center w-12 h-12 rounded-xl flex-shrink-0 transition-all duration-300"
                :class="[`bg-gradient-to-br ${tool.color}`, 'group-hover:bg-white/20 group-hover:scale-110']"
              >
                <component :is="tool.icon" class="w-6 h-6 text-white" />
              </div>
              <div>
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white group-hover:text-white transition-colors duration-300">{{ tool.label }}</h3>
                <p class="text-sm text-gray-600 dark:text-gray-400 group-hover:text-white/80 transition-colors duration-300">{{ tool.description }}</p>
              </div>
              <ChevronRightIcon class="w-6 h-6 text-gray-400 dark:text-gray-500 ml-auto group-hover:text-white transition-all duration-300 transform group-hover:translate-x-1" />
            </div>
          </button>
        </template>
      </div>
    </div>
  </div>

  <!-- Tool Drawer -->
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-300"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition-opacity duration-300"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div v-if="toolComponentShow" class="fixed inset-0 z-50 overflow-hidden">
        <!-- Backdrop -->
        <div class="absolute inset-0 bg-black/30 dark:bg-black/50 backdrop-blur-sm" @click="closeTool"></div>
        
        <!-- Drawer -->
        <Transition
          enter-active-class="transition-transform duration-500 ease-[cubic-bezier(0.16,1,0.3,1)]"
          enter-from-class="translate-x-full"
          enter-to-class="translate-x-0"
          leave-active-class="transition-transform duration-300 ease-in-out"
          leave-from-class="translate-x-0"
          leave-to-class="translate-x-full"
        >
          <div v-if="toolComponentShow" class="absolute right-0 top-0 h-full w-full max-w-3xl bg-gray-100 dark:bg-gray-900 shadow-2xl flex flex-col">
            <!-- Header -->
            <div class="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-800 flex-shrink-0">
              <div class="flex items-center space-x-4">
                <div v-if="currentTool" class="flex items-center justify-center w-10 h-10 rounded-xl" :class="`bg-gradient-to-br ${currentTool.color}`">
                  <component :is="currentTool.icon" class="w-5 h-5 text-white" />
                </div>
                <div>
                  <h2 class="text-xl font-semibold text-gray-900 dark:text-white">{{ currentTool?.label }}</h2>
                  <p class="text-sm text-gray-600 dark:text-gray-400">{{ currentTool?.description }}</p>
                </div>
              </div>
              <button
                @click="closeTool"
                class="flex items-center justify-center w-10 h-10 rounded-full bg-gray-200 dark:bg-gray-800 hover:bg-gray-300 dark:hover:bg-gray-700 transition-colors duration-200"
              >
                <XMarkIcon class="w-5 h-5 text-gray-600 dark:text-gray-400" />
              </button>
            </div>
            
            <!-- Content -->
            <div class="flex-1 overflow-y-auto p-6">
              <component :is="toolComponent" @closed="closeTool" />
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>
