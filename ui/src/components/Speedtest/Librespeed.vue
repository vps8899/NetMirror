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
    height: 80,
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
      colors: ['#0ea5e9'],
      fill: {
        ...baseChartOptions.fill,
        gradient: {
          ...baseChartOptions.fill.gradient,
          colorStops: [
            { offset: 0, color: '#0ea5e9', opacity: 0.8 },
            { offset: 100, color: '#0ea5e9', opacity: 0.1 }
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
      colors: ['#3b82f6'],
      fill: {
        ...baseChartOptions.fill,
        gradient: {
          ...baseChartOptions.fill.gradient,
          colorStops: [
            { offset: 0, color: '#3b82f6', opacity: 0.8 },
            { offset: 100, color: '#3b82f6', opacity: 0.1 }
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
  <div ref="containerRef" class="space-y-4">
    <!-- Results Display -->
    <div class="bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-4 border border-primary-200/30 dark:border-primary-700/30 relative overflow-hidden shadow-lg">
      <!-- Speed Values -->
      <div class="grid grid-cols-2 gap-4 mb-4">
        <!-- Download -->
        <div class="text-center">
          <div class="flex items-center justify-center w-8 h-8 bg-primary-100 dark:bg-primary-900/30 rounded-lg mx-auto mb-2">
            <ArrowDownIcon class="w-4 h-4 text-primary-600 dark:text-primary-400" />
          </div>
          <h4 class="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">{{ $t('librespeed_download') }}</h4>
          <p class="text-2xl font-bold text-primary-600 dark:text-primary-400">{{ downloadText }}</p>
          <span class="text-xs text-gray-500 dark:text-gray-400">Mbps</span>
        </div>
        
        <!-- Upload -->
        <div class="text-center">
          <div class="flex items-center justify-center w-8 h-8 bg-blue-100 dark:bg-blue-900/30 rounded-lg mx-auto mb-2">
            <ArrowUpIcon class="w-4 h-4 text-blue-600 dark:text-blue-400" />
          </div>
          <h4 class="text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">{{ $t('librespeed_upload') }}</h4>
          <p class="text-2xl font-bold text-blue-600 dark:text-blue-400">{{ uploadText }}</p>
          <span class="text-xs text-gray-500 dark:text-gray-400">Mbps</span>
        </div>
      </div>
      
      <!-- Charts -->
      <div class="grid grid-cols-2 gap-2">
        <VueApexCharts
          type="area"
          ref="chartDownloadRef"
          :options="charts.download.options"
          :series="charts.download.series"
        />
        <VueApexCharts
          type="area"
          ref="chartUploadRef"
          :options="charts.upload.options"
          :series="charts.upload.series"
        />
      </div>
    </div>

    <!-- Control Button -->
    <div class="text-center">
      <button
        @click="startOrStopSpeedtest"
        class="inline-flex items-center px-5 py-2.5 rounded-lg font-medium transition-all duration-200 transform hover:scale-105"
        :class="working 
          ? 'bg-red-500 hover:bg-red-600 text-white shadow-lg hover:shadow-red-500/30' 
          : 'bg-gradient-to-r from-primary-600 to-primary-700 hover:from-primary-700 hover:to-primary-800 text-white shadow-lg hover:shadow-primary-500/30'"
      >
        <component :is="working ? StopIcon : PlayIcon" class="w-4 h-4 mr-2" />
        <span v-if="working" class="flex items-center">
          <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2"></div>
          {{ $t('librespeed_stop') }}
        </span>
        <span v-else>{{ $t('librespeed_begin') }}</span>
      </button>
    </div>
  </div>
</template>
