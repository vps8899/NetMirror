<script setup>
import { ref, onMounted, onUnmounted, h, toRaw, watch } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { useNodeTool } from '@/composables/useNodeTool'
import { formatBytes } from '@/helper/unit'
import { ChartBarIcon, ArrowDownIcon, ArrowUpIcon } from '@heroicons/vue/24/outline'
import VueApexCharts from 'vue3-apexcharts'

const appStore = useAppStore()
const {
  selectedNode,
  selectedNodeName,
  selectedNodeLocation,
  hasSelectedNode,
  hasNodeSession,
  getEventSource
} = useNodeTool()

const interfaces = ref({})
const cardRef = ref()

const { apply } = useMotion(cardRef, {
  initial: { opacity: 0, y: 20 },
  enter: { opacity: 1, y: 0, transition: { duration: 500, delay: 500 } }
})

const currentNodeInterfaces = ref(new Set()) // 跟踪当前节点的网卡

// 计算属性：只显示当前节点的网卡接口
const currentInterfaces = computed(() => {
  const result = {}
  for (const [interfaceName, interfaceData] of Object.entries(interfaces.value)) {
    if (currentNodeInterfaces.value.has(interfaceName)) {
      result[interfaceName] = interfaceData
    }
  }
  return result
})

const handleCache = (e) => {
  console.log('=== Received InterfaceCache event ===')
  console.log('Current selected node:', selectedNodeName.value)
  console.log('Raw cache data:', e.data)
  
  const data = JSON.parse(e.data)
  console.log('Parsed cache data:', data)
  
  // 清空当前节点的网卡记录
  currentNodeInterfaces.value.clear()
  
  for (const ifaceIndex in data) {
    const iface = data[ifaceIndex]
    const ifaceName = iface.InterfaceName
    
    console.log('Processing interface:', ifaceName, 'for node:', selectedNodeName.value)
    
    // 记录这是当前节点的网卡
    currentNodeInterfaces.value.add(ifaceName)
    
    if (!interfaces.value.hasOwnProperty(ifaceName)) {
      console.log('Creating new graph for interface:', ifaceName)
      createGraph(ifaceName)
    }
    const localIface = interfaces.value[ifaceName]
    for (const point of data[ifaceIndex].Caches) {
      localIface.receive = point[1]
      localIface.send = point[2]
      updateSerieByInterface(ifaceName, localIface, new Date(point[0] * 1000))
    }
  }
  
  console.log('Current node interfaces:', Array.from(currentNodeInterfaces.value))
}

const handleTrafficUpdate = (e) => {
  console.log('Received InterfaceTraffic event:', e.data)
  const data = e.data.split(',')
  const ifaceName = data[0]
  const time = data[1]

  console.log('Traffic update for interface:', ifaceName, 'node:', selectedNodeName.value)

  // 只处理属于当前节点的网卡
  if (!currentNodeInterfaces.value.has(ifaceName)) {
    console.log('Ignoring traffic update for interface not belonging to current node:', ifaceName)
    return
  }

  if (!interfaces.value.hasOwnProperty(ifaceName)) {
    console.log('Creating new interface graph for:', ifaceName)
    createGraph(ifaceName)
    currentNodeInterfaces.value.add(ifaceName)
  }

  const iface = interfaces.value[ifaceName]
  iface.receive = data[2]
  iface.send = data[3]
  console.log('Updated interface data:', ifaceName, {receive: iface.receive, send: iface.send})
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

// 设置事件监听器
const setupEventListeners = () => {
  console.log('=== TrafficDisplay setupEventListeners ===')
  console.log('selectedNode:', selectedNode.value)
  console.log('hasSelectedNode:', hasSelectedNode.value)
  console.log('hasNodeSession:', hasNodeSession.value)
  
  try {
    let source
    // 如果没有选中节点，直接使用appStore的EventSource（当前节点）
    if (!hasSelectedNode.value || !hasNodeSession.value) {
      console.log('No selected node or session, using appStore EventSource')
      source = appStore.source
      if (!source) {
        console.error('No EventSource available from appStore')
        return
      }
    } else {
      source = getEventSource()
    }
    
    console.log('Successfully got event source:', source)
    console.log('Event source URL:', source?.url)
    console.log('Event source readyState:', source?.readyState)
    
    // 移除现有的监听器（防止重复添加）
    source.removeEventListener('InterfaceCache', handleCache)
    source.removeEventListener('InterfaceTraffic', handleTrafficUpdate)
    
    // 添加新的监听器
    source.addEventListener('InterfaceCache', handleCache)
    source.addEventListener('InterfaceTraffic', handleTrafficUpdate)
    
    console.log('Event listeners added successfully')
    console.log('Current interfaces count:', Object.keys(interfaces.value).length)
    
  } catch (error) {
    console.error('ERROR in setupEventListeners:', error)
    console.error('Error message:', error.message)
    console.error('Error stack:', error.stack)
  }
}

// 清理事件监听器
const cleanupEventListeners = () => {
  try {
    let source
    // 如果没有选中节点，直接使用appStore的EventSource（当前节点）
    if (!hasSelectedNode.value || !hasNodeSession.value) {
      source = appStore.source
    } else {
      source = getEventSource()
    }
    
    if (source) {
      source.removeEventListener('InterfaceCache', handleCache)
      source.removeEventListener('InterfaceTraffic', handleTrafficUpdate)
    }
  } catch (error) {
    console.warn('Failed to cleanup event listeners:', error)
  }
}

// 监听appStore source的变化（用于处理默认节点情况）
watch(() => appStore.source, (newSource) => {
  console.log('=== TrafficDisplay: AppStore source changed ===')
  console.log('New source available:', !!newSource)
  
  // 如果没有选中节点，且appStore的source变为可用，设置监听器
  if (!hasSelectedNode.value && newSource) {
    console.log('Setting up listeners for default node (appStore source)')
    setupEventListeners()
  }
})

// 监听节点session状态变化
watch(() => hasNodeSession.value, (hasSession) => {
  console.log('=== TrafficDisplay: Node session status changed ===')
  console.log('Has session:', hasSession)
  
  if (hasSession) {
    console.log('Session established, setting up traffic listeners...')
    setupEventListeners()
  }
})

// 监听节点变化，重新设置事件监听
watch(() => selectedNode.value, (newNode, oldNode) => {
  console.log('=== TrafficDisplay: Node changed ===')
  console.log('Old node:', oldNode?.name)
  console.log('New node:', newNode?.name)
  
  // 只要节点发生了变化就清空接口数据和节点网卡记录，无论新节点是否存在
  console.log('Clearing interfaces data due to node change...')
  interfaces.value = {}
  currentNodeInterfaces.value.clear()
  console.log('Interfaces data and node interfaces cleared')
  
  if (newNode !== oldNode) {
    console.log('Cleaning up old listeners...')
    // 清理旧的监听器 - 使用try-catch防止错误
    try {
      cleanupEventListeners()
    } catch (error) {
      console.warn('Error cleaning up listeners:', error)
    }
    
    // 新的监听器会在hasNodeSession变化时设置
  }
}, { immediate: false })

onMounted(() => {
  console.log('TrafficDisplay mounted, current selectedNode:', selectedNode.value)
  console.log('Current interfaces before setup:', interfaces.value)
  console.log('Has node session:', hasNodeSession.value)
  console.log('AppStore source available:', !!appStore.source)
  
  // 总是尝试设置监听器，如果没有选中节点就用appStore的source
  setupEventListeners()
  
  apply()
})

onUnmounted(() => {
  try {
    cleanupEventListeners()
  } catch (error) {
    console.warn('Error cleaning up listeners on unmount:', error)
  }
  // 清空接口数据和节点网卡记录确保不会留在内存中
  interfaces.value = {}
  currentNodeInterfaces.value.clear()
})
</script>

<template>
  <div ref="cardRef" class="bg-white/90 dark:bg-gray-800/90 backdrop-blur-sm rounded-xl shadow-lg border border-primary-200/30 dark:border-primary-700/30 overflow-hidden">
    <div class="p-6">
      <div v-if="Object.keys(currentInterfaces).length === 0" class="text-center py-12">
        <ChartBarIcon class="w-16 h-16 text-gray-400/50 dark:text-gray-500/50 mx-auto mb-4" />
        <h3 class="text-lg font-medium text-gray-700 dark:text-gray-300 mb-2">No Traffic Data</h3>
        <p class="text-gray-500 dark:text-gray-400">Waiting for network interface data...</p>
      </div>
      
      <div v-else :class="Object.keys(currentInterfaces).length === 1 ? 'block' : 'grid grid-cols-1 xl:grid-cols-2 gap-6'">
        <div 
          v-for="(interfaceData, interfaceName) in currentInterfaces" 
          :key="interfaceName"
          class="bg-gray-50 dark:bg-gray-700/50 rounded-xl p-6 border border-gray-200 dark:border-gray-600"
          :class="Object.keys(currentInterfaces).length === 1 ? 'mx-auto max-w-4xl' : ''"
        >
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ interfaceName }}</h3>
            <div class="flex items-center space-x-2">
              <div class="w-3 h-3 bg-green-500 rounded-full"></div>
              <span class="text-sm text-gray-600 dark:text-gray-400">Active</span>
            </div>
          </div>
          
          <!-- Stats -->
          <div :class="Object.keys(currentInterfaces).length === 1 ? 'flex justify-center gap-16 mb-6' : 'grid grid-cols-2 gap-4 mb-6'">
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

