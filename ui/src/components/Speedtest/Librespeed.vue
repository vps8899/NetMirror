<script setup>
import { ref, onMounted, toRaw, computed } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { PlayIcon, StopIcon, ArrowDownIcon, ArrowUpIcon, ChartBarIcon } from '@heroicons/vue/24/outline'
import VueApexCharts from 'vue3-apexcharts'

const appStore = useAppStore()
const containerRef = ref()

const { apply } = useMotion(containerRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { type: 'spring', stiffness: 100, damping: 15 } }
})

let workerInstance = null
let workerTimer = null
const working = ref(false)
const uploadText = ref('0')
const downloadText = ref('0')
const chartDownloadRef = ref()
const chartUploadRef = ref()

const gaugeValue = (value) => {
  const val = parseFloat(value)
  if (val < 1) return val * 100
  if (val < 10) return val * 10
  return Math.min(val, 1000)
}

const downloadGauge = computed(() => gaugeValue(downloadText.value))
const uploadGauge = computed(() => gaugeValue(uploadText.value))

const baseChartOptions = {
  chart: {
    height: 150,
    foreColor: '#6b7280',
    animations: {
      enabled: true,
      easing: 'linear',
      dynamicAnimation: {
        speed: 300
      }
    },
    zoom: {
      enabled: false
    },
    toolbar: {
      show: false
    },
    background: 'transparent'
  },
  tooltip: {
    enabled: false
  },
  xaxis: {
    type: 'category',
    categories: [''],
    labels: {
      show: false
    },
    axisBorder: {
      show: false
    },
    axisTicks: {
      show: false
    }
  },
  yaxis: {
    show: false,
    min: 0,
  },
  dataLabels: {
    enabled: false
  },
  markers: {
    size: 0
  },
  stroke: {
    curve: 'smooth',
    width: 3
  },
  fill: {
    type: 'gradient',
    gradient: {
      shadeIntensity: 1,
      opacityFrom: 0.7,
      opacityTo: 0.1,
      stops: [0, 90, 100]
    }
  },
  grid: {
    show: false
  }
}

const baseSeries = {
  type: 'area',
  name: 'Speed',
  data: []
}

const charts = ref({
  download: {
    ref: null,
    options: { 
      ...baseChartOptions,
      colors: ['#10b981'],
      fill: {
        ...baseChartOptions.fill,
        gradient: {
          ...baseChartOptions.fill.gradient,
          colorStops: [
            { offset: 0, color: '#10b981', opacity: 0.8 },
            { offset: 100, color: '#10b981', opacity: 0.1 }
          ]
        }
      }
    },
    series: [{ ...baseSeries, name: 'Download' }],
    data: [],
    categories: []
  },
  upload: {
    ref: null,
    options: { 
      ...baseChartOptions,
      colors: ['#8b5cf6'],
      fill: {
        ...baseChartOptions.fill,
        gradient: {
          ...baseChartOptions.fill.gradient,
          colorStops: [
            { offset: 0, color: '#8b5cf6', opacity: 0.8 },
            { offset: 100, color: '#8b5cf6', opacity: 0.1 }
          ]
        }
      }
    },
    series: [{ ...baseSeries, name: 'Upload' }],
    data: [],
    categories: []
  }
})

// Generate unique chart IDs
const generateChartIds = () => {
  for (const chartId in charts.value) {
    charts.value[chartId].options.chart.id = 
      'chart-librespeed-' + chartId + '-' + (Math.random() + 1).toString(36).substring(2)
  }
}

const startOrStopSpeedtest = (force = false) => {
  if (workerInstance != null) {
    workerInstance.postMessage('abort')
    clearInterval(workerTimer)
    workerInstance = null
    
    if (force) {
      uploadText.value = '0'
      downloadText.value = '0'
      // Reset charts
      charts.value.download.data = []
      charts.value.download.categories = []
      charts.value.upload.data = []
      charts.value.upload.categories = []
    }
    working.value = false
    return
  }
  
  working.value = true
  uploadText.value = '0'
  downloadText.value = '0'
  
  // Reset chart data
  charts.value.download.data = []
  charts.value.download.categories = []
  charts.value.upload.data = []
  charts.value.upload.categories = []
  
  workerInstance = new Worker('./speedtest_worker.js')
  workerInstance.onmessage = (e) => {
    const nowPointName = new Date().toLocaleTimeString()
    const data = JSON.parse(e.data)
    const status = data.testState
    
    if (status >= 4) {
      return startOrStopSpeedtest(false)
    }

    if (status === 1 && data.dlStatus === 0) {
      downloadText.value = '0'
      uploadText.value = '0'
    }

    if (data.ulStatus) {
      uploadText.value = data.ulStatus
      charts.value.upload.data.push(parseFloat(data.ulStatus))
      charts.value.upload.categories.push(nowPointName)
      
      if (chartUploadRef.value) {
        chartUploadRef.value.updateOptions({
          xaxis: {
            categories: toRaw(charts.value.upload.categories)
          }
        })
        chartUploadRef.value.updateSeries([{
          name: 'Upload',
          data: toRaw(charts.value.upload.data)
        }])
      }
      return
    }

    if (data.dlStatus) {
      downloadText.value = data.dlStatus
      charts.value.download.data.push(parseFloat(data.dlStatus))
      charts.value.download.categories.push(nowPointName)
      
      if (chartDownloadRef.value) {
        chartDownloadRef.value.updateOptions({
          xaxis: {
            categories: toRaw(charts.value.download.categories)
          }
        })
        chartDownloadRef.value.updateSeries([{
          name: 'Download',
          data: toRaw(charts.value.download.data)
        }])
      }
    }
  }
  
  workerInstance.postMessage(
    'start ' + JSON.stringify({
      test_order: 'D_U',
      url_dl: './session/' + appStore.sessionId + '/speedtest/download',
      url_ul: './session/' + appStore.sessionId + '/speedtest/upload',
      url_ping: './session/' + appStore.sessionId + '/speedtest/upload'
    })
  )
  
  workerTimer = setInterval(() => {
    workerInstance.postMessage('status')
  }, 200)
}

onMounted(() => {
  apply()
  generateChartIds()
})
</script>

<template>
  <div ref="containerRef" class="space-y-6">
    <div class="text-center">
      <ChartBarIcon class="w-12 h-12 text-emerald-500 mx-auto mb-4" />
      <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">
        {{ $t('server_speedtest') }}
      </h3>
      <p class="text-gray-600 dark:text-gray-400">
        Real-time bandwidth measurement using LibreSpeed
      </p>
    </div>

    <!-- Results Display -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Download -->
      <div class="bg-white/50 dark:bg-gray-700/30 rounded-2xl p-6 border border-gray-200 dark:border-gray-700/50 relative overflow-hidden">
        <div class="flex items-center space-x-4 mb-4">
          <div class="flex items-center justify-center w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-xl flex-shrink-0">
            <ArrowDownIcon class="w-6 h-6 text-green-600 dark:text-green-400" />
          </div>
          <div>
            <h4 class="text-lg font-semibold text-gray-900 dark:text-white">{{ $t('librespeed_download') }}</h4>
            <p class="text-3xl font-bold text-green-600 dark:text-green-400">{{ downloadText }} <span class="text-xl">Mbps</span></p>
          </div>
        </div>
        <VueApexCharts
          type="area"
          ref="chartDownloadRef"
          :options="charts.download.options"
          :series="charts.download.series"
        />
      </div>

      <!-- Upload -->
      <div class="bg-white/50 dark:bg-gray-700/30 rounded-2xl p-6 border border-gray-200 dark:border-gray-700/50 relative overflow-hidden">
        <div class="flex items-center space-x-4 mb-4">
          <div class="flex items-center justify-center w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-xl flex-shrink-0">
            <ArrowUpIcon class="w-6 h-6 text-purple-600 dark:text-purple-400" />
          </div>
          <div>
            <h4 class="text-lg font-semibold text-gray-900 dark:text-white">{{ $t('librespeed_upload') }}</h4>
            <p class="text-3xl font-bold text-purple-600 dark:text-purple-400">{{ uploadText }} <span class="text-xl">Mbps</span></p>
          </div>
        </div>
        <VueApexCharts
          type="area"
          ref="chartUploadRef"
          :options="charts.upload.options"
          :series="charts.upload.series"
        />
      </div>
    </div>

    <!-- Control Button -->
    <div class="text-center pt-4">
      <button
        @click="startOrStopSpeedtest"
        class="inline-flex items-center px-8 py-4 rounded-full font-semibold text-lg transition-all duration-300 transform hover:scale-105"
        :class="working 
          ? 'bg-red-500 hover:bg-red-600 text-white shadow-lg hover:shadow-red-500/30' 
          : 'bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 text-white shadow-lg hover:shadow-emerald-500/30'"
      >
        <component :is="working ? StopIcon : PlayIcon" class="w-6 h-6 mr-3" />
        <span v-if="working" class="flex items-center">
          <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
          {{ $t('librespeed_stop') }}
        </span>
        <span v-else>{{ $t('librespeed_begin') }}</span>
      </button>
    </div>
  </div>
</template>
