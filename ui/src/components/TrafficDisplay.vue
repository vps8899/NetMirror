<script setup>
import { ref, onMounted, onUnmounted, h, toRaw } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { formatBytes } from '@/helper/unit'
import { ChartBarIcon, ArrowDownIcon, ArrowUpIcon } from '@heroicons/vue/24/outline'
import VueApexCharts from 'vue3-apexcharts'

const appStore = useAppStore()
const interfaces = ref({})
const cardRef = ref()

const { apply } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 500, delay: 500 } }
})

const handleCache = (e) => {
  const data = JSON.parse(e.data)
  for (const ifaceIndex in data) {
    const iface = data[ifaceIndex]
    const ifaceName = iface.InterfaceName
    if (!interfaces.value.hasOwnProperty(ifaceName)) {
      createGraph(ifaceName)
    }
    const localIface = interfaces.value[ifaceName]
    for (const point of data[ifaceIndex].Caches) {
      localIface.receive = point[1]
      localIface.send = point[2]
      updateSerieByInterface(ifaceName, localIface, new Date(point[0] * 1000))
    }
  }
}

const handleTrafficUpdate = (e) => {
  const data = e.data.split(',')
  const ifaceName = data[0]
  const time = data[1]

  if (!interfaces.value.hasOwnProperty(ifaceName)) {
    createGraph(ifaceName)
  }

  const iface = interfaces.value[ifaceName]
  iface.receive = data[2]
  iface.send = data[3]
  updateSerieByInterface(ifaceName, iface, new Date(time * 1000))
}

const createGraph = (interfaceName) => {
  const theRef = ref()
  interfaces.value[interfaceName] = {
    ref: null,
    theComponent: null,
    traffic: {
      receive: null,
      send: null
    },
    lines: [[], []],
    categories: [],
    receive: 0,
    send: 0,
    lastReceive: 0,
    lastSend: 0,
    chartOptions: {
      chart: {
        id: 'interface-' + interfaceName + '-chart',
        foreColor: '#6b7280',
        animations: {
          enabled: true,
          easing: 'linear',
          dynamicAnimation: {
            speed: 1000
          },
          animateGradually: {
            enabled: true,
            delay: 300
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
        theme: 'dark'
      },
      xaxis: {
        range: 10,
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
        labels: {
          formatter: (value) => {
            return formatBytes(value, 1, true)
          },
          style: {
            fontSize: '12px'
          }
        }
      },
      dataLabels: {
        enabled: false
      },
      markers: {
        size: 0
      },
      stroke: {
        curve: 'smooth',
        width: 2
      },
      fill: {
        type: 'gradient',
        gradient: {
          shadeIntensity: 1,
          opacityFrom: 0.6,
          opacityTo: 0.1,
          stops: [0, 90, 100]
        }
      },
      grid: {
        borderColor: '#374151',
        strokeDashArray: 3
      },
      colors: ['#10b981', '#8b5cf6']
    },
    series: [
      {
        type: 'area',
        name: 'Receive',
        data: []
      },
      {
        type: 'area',
        name: 'Send',
        data: []
      }
    ]
  }
  
  interfaces.value[interfaceName].theComponent = () =>
    h(VueApexCharts, {
      ref: theRef,
      type: 'area',
      options: interfaces.value[interfaceName].chartOptions,
      series: interfaces.value[interfaceName].series,
      height: '200px'
    })
  interfaces.value[interfaceName].ref = theRef
}

const updateSerieByInterface = (interfaceName, iface, date = null) => {
  let nowPointName
  if (date === null) {
    date = new Date()
  }

  nowPointName = date.getHours().toString().padStart(2, '0') +
    ':' + date.getMinutes().toString().padStart(2, '0') +
    ':' + date.getSeconds().toString().padStart(2, '0')

  const categories = iface.categories
  const receiveDatas = iface.lines[0]
  const sendDatas = iface.lines[1]

  if (iface.lastReceive === 0) {
    iface.lastReceive = iface.receive
  }

  if (iface.lastSend === 0) {
    iface.lastSend = iface.send
  }

  const receive = iface.receive - iface.lastReceive
  const send = iface.send - iface.lastSend
  iface.lastReceive = iface.receive
  iface.lastSend = iface.send
  iface.traffic.receive = receive
  iface.traffic.send = send
  
  receiveDatas.push(receive)
  sendDatas.push(send)
  categories.push(nowPointName)
  
  if (receiveDatas.length > 30) {
    interfaces.value[interfaceName].categories = categories.slice(-10)
    interfaces.value[interfaceName].lines[0] = receiveDatas.slice(-10)
    interfaces.value[interfaceName].lines[1] = sendDatas.slice(-10)
  }
  
  const finalCategories = categories.slice(0)
  const finalReceiveDatas = receiveDatas.slice(0)
  const finalSendDatas = sendDatas.slice(0)
  
  if (!iface.ref) return
  
  iface.ref.updateOptions({
    xaxis: {
      categories: toRaw(finalCategories)
    }
  })

  iface.ref.updateSeries([
    {
      name: 'Receive',
      data: toRaw(finalReceiveDatas)
    },
    {
      name: 'Send',
      data: toRaw(finalSendDatas)
    }
  ])
}

onMounted(() => {
  appStore.source.addEventListener('InterfaceCache', handleCache)
  appStore.source.addEventListener('InterfaceTraffic', handleTrafficUpdate)
  apply()
})

onUnmounted(() => {
  appStore.source.removeEventListener('InterfaceCache', handleCache)
  appStore.source.removeEventListener('InterfaceTraffic', handleTrafficUpdate)
})
</script>

<template>
  <div ref="cardRef" class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden">
    <div class="p-6">
      <div v-if="Object.keys(interfaces).length === 0" class="text-center py-12">
        <ChartBarIcon class="w-16 h-16 text-gray-400/50 dark:text-gray-500/50 mx-auto mb-4" />
        <h3 class="text-lg font-medium text-gray-700 dark:text-gray-300 mb-2">No Traffic Data</h3>
        <p class="text-gray-500 dark:text-gray-400">Waiting for network interface data...</p>
      </div>
      
      <div v-else :class="Object.keys(interfaces).length === 1 ? 'block' : 'grid grid-cols-1 xl:grid-cols-2 gap-6'">
        <div 
          v-for="(interfaceData, interfaceName) in interfaces" 
          :key="interfaceName"
          class="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-6 border border-gray-200 dark:border-gray-600"
          :class="Object.keys(interfaces).length === 1 ? 'mx-auto max-w-4xl' : ''"
        >
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ interfaceName }}</h3>
            <div class="flex items-center space-x-2">
              <div class="w-3 h-3 bg-green-500 rounded-full"></div>
              <span class="text-sm text-gray-600 dark:text-gray-400">Active</span>
            </div>
          </div>
          
          <!-- Stats -->
          <div :class="Object.keys(interfaces).length === 1 ? 'flex justify-center gap-16 mb-6' : 'grid grid-cols-2 gap-4 mb-6'">
            <div class="text-center">
              <div class="flex items-center justify-center space-x-2 mb-2">
                <ArrowDownIcon class="w-4 h-4 text-green-600 dark:text-green-400" />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                  {{ $t('server_bandwidth_graph_receive') }}
                </span>
              </div>
              <div class="space-y-1">
                <p class="text-lg font-bold text-green-600 dark:text-green-400">
                  {{ formatBytes(interfaceData.traffic?.receive || 0, 1, true) }}
                </p>
                <p class="text-xs text-gray-500 dark:text-gray-400">
                  Total: {{ formatBytes(interfaceData.receive || 0) }}
                </p>
              </div>
            </div>
            
            <div class="text-center">
              <div class="flex items-center justify-center space-x-2 mb-2">
                <ArrowUpIcon class="w-4 h-4 text-purple-600 dark:text-purple-400" />
                <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                  {{ $t('server_bandwidth_graph_sended') }}
                </span>
              </div>
              <div class="space-y-1">
                <p class="text-lg font-bold text-purple-600 dark:text-purple-400">
                  {{ formatBytes(interfaceData.traffic?.send || 0, 1, true) }}
                </p>
                <p class="text-xs text-gray-500 dark:text-gray-400">
                  Total: {{ formatBytes(interfaceData.send || 0) }}
                </p>
              </div>
            </div>
          </div>
          
          <!-- Chart -->
          <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-600">
            <component :is="interfaceData.theComponent" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

