<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { formatBytes } from '@/helper/unit'
import { 
  PlayIcon, 
  StopIcon, 
  SignalIcon, 
  ArrowDownIcon, 
  ArrowUpIcon,
  ClockIcon,
  ServerIcon,
  QueueListIcon
} from '@heroicons/vue/24/outline'
import { markRaw } from 'vue'

const appStore = useAppStore()
const working = ref(false)
const serverId = ref('')
const isCrash = ref(false)
const isQueue = ref(false)
const isSpeedtest = ref(false)
const action = ref('')

const containerRef = ref()
const resultRef = ref()

const { apply: applyContainer } = useMotion(containerRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 300 } }
})

const { apply: applyResult } = useMotion(resultRef, {
  initial: { opacity: 0, scale: 0.95 },
  enter: { opacity: 1, scale: 1, transition: { type: 'spring', stiffness: 100, damping: 15 } }
})

let abortController = markRaw(new AbortController())

const queueStat = ref({
  pos: 0,
  total: 0
})

const progress = ref({
  sub: 0,
  full: 0
})

const speedtestData = ref({
  ping: '0',
  download: '',
  upload: '',
  result: '',
  serverInfo: {
    id: '',
    name: '',
    pos: ''
  }
})

const progressRadius = 60
const progressCircumference = 2 * Math.PI * progressRadius

const progressOffset = computed(() => {
  return progressCircumference - (progress.value.full / 100) * progressCircumference
})

const handleMessage = (e) => {
  const data = JSON.parse(e.data)
  
  switch (data.type) {
    case 'queue':
      isQueue.value = true
      queueStat.value.pos = data.pos
      queueStat.value.total = data.totalPos
      break
      
    case 'testStart':
      isQueue.value = false
      isSpeedtest.value = true
      speedtestData.value.serverInfo.id = data.server.id
      speedtestData.value.serverInfo.name = data.server.name
      speedtestData.value.serverInfo.pos = data.server.country + ' - ' + data.server.location
      break
      
    case 'ping':
      action.value = 'Testing latency'
      speedtestData.value.ping = data.ping.latency.toFixed(2)
      break
      
    case 'download':
      action.value = 'Download test'
      speedtestData.value.download = formatBytes(data.download.bandwidth, 2, true)
      progress.value.sub = Math.round(data.download.progress * 100)
      progress.value.full = Math.round(progress.value.sub / 2)
      break
      
    case 'upload':
      action.value = 'Upload test'
      speedtestData.value.upload = formatBytes(data.upload.bandwidth, 2, true)
      progress.value.sub = Math.round(data.upload.progress * 100)
      progress.value.full = 50 + Math.round(progress.value.sub / 2)
      break
      
    case 'result':
      speedtestData.value.result = data.result.url
      speedtestData.value.download = formatBytes(data.download.bandwidth, 2, true)
      speedtestData.value.upload = formatBytes(data.upload.bandwidth, 2, true)
      progress.value.full = 100
      applyResult()
      break
  }
}

const stopTest = () => {
  abortController.abort('')
  appStore.source.removeEventListener('SpeedtestStream', handleMessage)
  isSpeedtest.value = false
  working.value = false
}

const speedtest = async () => {
  if (working.value) return stopTest()
  
  abortController = new AbortController()
  working.value = true
  isSpeedtest.value = true
  action.value = ''
  isCrash.value = false
  isQueue.value = false
  
  // Reset data
  progress.value = { sub: 0, full: 0 }
  speedtestData.value = {
    ping: '0',
    download: '',
    upload: '',
    result: '',
    serverInfo: { id: '', name: '', pos: '' }
  }
  
  appStore.source.addEventListener('SpeedtestStream', handleMessage)
  
  try {
    await appStore.requestMethod(
      'speedtest_dot_net',
      { node_id: serverId.value },
      abortController.signal
    )
  } catch (e) {
    if (e.name !== 'AbortError') {
      isCrash.value = true
    }
  }
  
  appStore.source.removeEventListener('SpeedtestStream', handleMessage)
  working.value = false
}

onMounted(() => {
  applyContainer()
})

onUnmounted(() => {
  stopTest()
})
</script>

<template>
  <div ref="containerRef" class="space-y-6">
    <!-- Control Panel -->
    <div class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-200 dark:border-gray-700">
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="relative flex-1">
          <ServerIcon class="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            v-model="serverId"
            :disabled="working"
            type="text"
            placeholder="Server ID (Optional)"
            class="w-full pl-10 pr-4 py-3 bg-transparent border-0 rounded-xl focus:ring-0 transition-all duration-200 disabled:opacity-50"
            @keyup.enter="speedtest"
          />
        </div>
        <button
          @click="speedtest"
          class="inline-flex items-center justify-center px-6 py-3 rounded-xl font-medium transition-all duration-200"
          :class="working 
            ? 'bg-red-500 hover:bg-red-600 text-white' 
            : 'bg-purple-500 hover:bg-purple-600 text-white hover:shadow-lg'"
        >
          <component :is="working ? StopIcon : PlayIcon" class="w-5 h-5 mr-2" />
          {{ working ? 'Stop Test' : 'Start Test' }}
        </button>
      </div>
    </div>

    <!-- Queue Status -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
    >
      <div v-if="isQueue" class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-xl p-6 text-center">
        <QueueListIcon class="w-10 h-10 text-amber-500 mx-auto mb-3" />
        <h3 class="text-lg font-semibold text-amber-900 dark:text-amber-100 mb-1">
          Test in Queue
        </h3>
        <p class="text-amber-700 dark:text-amber-300">
          Position {{ queueStat.pos }} of {{ queueStat.total }}
        </p>
      </div>
    </Transition>

    <!-- Test Progress -->
    <Transition
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
    >
      <div v-if="!isQueue && isSpeedtest && working" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 text-center">
        <div class="relative w-40 h-40 mx-auto mb-4">
          <svg class="w-full h-full" viewBox="0 0 140 140">
            <circle class="text-gray-200 dark:text-gray-700" stroke-width="10" stroke="currentColor" fill="transparent" r="60" cx="70" cy="70" />
            <circle 
              class="text-purple-500"
              stroke-width="10"
              :stroke-dasharray="progressCircumference"
              :stroke-dashoffset="progressOffset"
              stroke-linecap="round"
              stroke="currentColor"
              fill="transparent"
              r="60"
              cx="70"
              cy="70"
              style="transition: stroke-dashoffset 0.3s;"
            />
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center">
            <span class="text-3xl font-bold text-gray-900 dark:text-white">{{ progress.full }}%</span>
            <span class="text-sm text-gray-500 dark:text-gray-400">{{ action }}</span>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Results -->
    <Transition
      enter-active-class="transition-all duration-500 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
    >
      <div v-if="speedtestData.ping !== '0'" ref="resultRef" class="space-y-6">
        <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-6 text-center">
            <!-- Ping -->
            <div>
              <div class="inline-flex items-center justify-center w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-xl mb-3">
                <ClockIcon class="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Latency</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white">
                {{ speedtestData.ping === '0' ? '...' : `${speedtestData.ping} ms` }}
              </p>
            </div>
            
            <!-- Download -->
            <div>
              <div class="inline-flex items-center justify-center w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-xl mb-3">
                <ArrowDownIcon class="w-6 h-6 text-green-600 dark:text-green-400" />
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Download</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white">
                {{ speedtestData.download || '...' }}
              </p>
            </div>
            
            <!-- Upload -->
            <div>
              <div class="inline-flex items-center justify-center w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-xl mb-3">
                <ArrowUpIcon class="w-6 h-6 text-purple-600 dark:text-purple-400" />
              </div>
              <p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Upload</p>
              <p class="text-2xl font-bold text-gray-900 dark:text-white">
                {{ speedtestData.upload || '...' }}
              </p>
            </div>
          </div>
        </div>

        <div v-if="speedtestData.serverInfo.id" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
            <ServerIcon class="w-5 h-5 mr-3 text-purple-500" />
            Test Server Information
          </h3>
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-center">
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">ID</p>
              <p class="font-semibold text-gray-800 dark:text-gray-200">{{ speedtestData.serverInfo.id }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">Provider</p>
              <p class="font-semibold text-gray-800 dark:text-gray-200">{{ speedtestData.serverInfo.name }}</p>
            </div>
            <div>
              <p class="text-sm text-gray-500 dark:text-gray-400">Location</p>
              <p class="font-semibold text-gray-800 dark:text-gray-200">{{ speedtestData.serverInfo.pos }}</p>
            </div>
          </div>
        </div>

        <div v-if="speedtestData.result" class="text-center">
          <a :href="speedtestData.result" target="_blank" class="inline-block group">
            <img
              :src="speedtestData.result + '.png'"
              alt="Speedtest Result"
              class="max-w-full h-auto rounded-xl shadow-lg group-hover:shadow-xl transition-all duration-300 group-hover:scale-105 border border-gray-200 dark:border-gray-700"
              style="max-width: 400px"
            />
            <p class="text-sm text-gray-600 dark:text-gray-400 mt-3 group-hover:text-purple-500 transition-colors">Click to view full results</p>
          </a>
        </div>
      </div>
    </Transition>
  </div>
</template>
