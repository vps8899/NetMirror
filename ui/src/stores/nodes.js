import { ref, computed, watch } from 'vue'
import { defineStore } from 'pinia'
import axios from 'axios'
import { useAppStore } from '@/stores/app'

export const useNodesStore = defineStore('nodes', () => {
  // 节点相关状态
  const nodes = ref([])
  const selectedNode = ref(null)
  const currentNode = ref(null)
  const latencies = ref({})
  const loading = ref(false)
  const pingStates = ref({})

  // Session管理
  const selectedNodeSession = ref(null)
  const selectedNodeSource = ref(null)

  // 生成节点唯一键
  const getNodeKey = (node) => {
    if (!node) return ''
    return `${node.name}_${node.url.replace(/[^a-zA-Z0-9]/g, '_')}`
  }

  // 获取当前页面URL
  const getCurrentURL = () => {
    const protocol = window.location.protocol
    const host = window.location.host
    const port = window.location.port
    
    let baseURL = `${protocol}//${window.location.hostname}`
    
    if (port && ((protocol === 'http:' && port !== '80') || (protocol === 'https:' && port !== '443'))) {
      baseURL += `:${port}`
    }
    
    return baseURL
  }

  // 检查是否为当前节点
  const isCurrentNode = (node) => {
    if (!node) return false
    const currentURL = getCurrentURL()
    return node.url.replace(/\/$/, '') === currentURL.replace(/\/$/, '')
  }

  // 根据延迟获取状态
  const getStatusByLatency = (latency) => {
    if (latency < 200) return 'good'
    if (latency < 500) return 'medium'
    return 'high'
  }

  // 获取状态文本
  const getStatusText = (status) => {
    switch (status) {
      case 'good': return 'Excellent'
      case 'medium': return 'Good'
      case 'high': return 'Slow'
      case 'error': return 'Offline'
      default: return 'Unknown'
    }
  }

  // 建立选定节点的Session连接
  const establishNodeSession = async (node) => {
    if (!node) return null

    // 如果是当前节点，使用现有的appStore session
    if (isCurrentNode(node)) {
      const appStore = useAppStore()
      return {
        sessionId: appStore.sessionId,
        source: appStore.source,
        config: appStore.config
      }
    }

    // 为其他节点建立新的Session连接
    return new Promise((resolve, reject) => {
      const eventSource = new EventSource(`${node.url}/session`)
      let sessionId = null
      let nodeConfig = null

      const timeout = setTimeout(() => {
        eventSource.close()
        reject(new Error('Session connection timeout'))
      }, 10000)

      eventSource.addEventListener('SessionId', (e) => {
        sessionId = e.data
        console.log('Node session established:', sessionId, 'for node:', node.name)
      })

      eventSource.addEventListener('Config', (e) => {
        nodeConfig = JSON.parse(e.data)
        console.log('Node config received for:', node.name, nodeConfig)
        
        // 只有当我们有了 sessionId 和 config 才算完成
        if (sessionId && nodeConfig) {
          clearTimeout(timeout)
          resolve({
            sessionId: sessionId,
            source: eventSource,
            config: nodeConfig
          })
        }
      })

      eventSource.onerror = (error) => {
        clearTimeout(timeout)
        eventSource.close()
        console.error('Failed to establish session for node:', node.name, error)
        reject(error)
      }
    })
  }

  // 清理选定节点的Session
  const cleanupNodeSession = () => {
    if (selectedNodeSource.value && !isCurrentNode(selectedNode.value)) {
      selectedNodeSource.value.close()
    }
    selectedNodeSession.value = null
    selectedNodeSource.value = null
  }

  // 获取节点列表
  const fetchNodes = async () => {
    loading.value = true
    try {
      const response = await fetch('/nodes')
      const data = await response.json()
      if (data.success) {
        nodes.value = data.nodes || []
        console.log('Fetched nodes:', nodes.value)
        
        // 设置当前节点
        const current = nodes.value.find(node => isCurrentNode(node))
        if (current) {
          currentNode.value = current
          if (!selectedNode.value) {
            await selectNode(current)
          }
        }
        
        // 立即测试延迟
        await testAllLatencies()
      }
    } catch (error) {
      console.error('Failed to fetch nodes:', error)
    } finally {
      loading.value = false
    }
  }

  // 测试单个节点延迟
  const testNodeLatency = async (node) => {
    if (!node) return
    
    try {
      const timestamp = Date.now()
      const targetUrl = isCurrentNode(node) ? '/nodes/latency' : `${node.url}/nodes/latency`
      
      const response = await fetch(`${targetUrl}?timestamp=${timestamp}`, {
        method: 'GET',
        mode: 'cors',
        cache: 'no-cache',
        signal: AbortSignal.timeout(5000)
      })
      
      if (response.ok) {
        const data = await response.json()
        const latency = Date.now() - timestamp
        console.log(`Latency response for ${node.name}:`, data)
        if (data.success) {
          const nodeKey = getNodeKey(node)
          latencies.value[nodeKey] = {
            latency: latency,
            status: getStatusByLatency(latency)
          }
          console.log(`Updated latencies for ${node.name} (${nodeKey}):`, latencies.value[nodeKey])
        } else {
          throw new Error('Server returned error')
        }
      } else {
        throw new Error('Server not responding properly')
      }
    } catch (error) {
      console.error('Failed to test latency for', node.name, error)
      const nodeKey = getNodeKey(node)
      latencies.value[nodeKey] = {
        latency: -1,
        status: 'error'
      }
    }
  }

  // 测试所有节点延迟
  const testAllLatencies = async () => {
    if (nodes.value.length === 0) return
    
    loading.value = true
    try {
      for (const node of nodes.value) {
        await testNodeLatency(node)
        await new Promise(resolve => setTimeout(resolve, 100))
      }
    } finally {
      loading.value = false
    }
  }

  // 单独ping节点
  const pingSingleNode = async (node) => {
    if (!node) return
    
    const nodeKey = getNodeKey(node)
    pingStates.value[nodeKey] = { isPinging: true }
    await testNodeLatency(node)
    pingStates.value[nodeKey] = { isPinging: false }
  }

  // 选择节点并建立Session
  const selectNode = async (node) => {
    if (!node || !nodes.value.includes(node)) return

    try {
      // 清理之前的Session
      cleanupNodeSession()
      
      // 设置新的选定节点
      selectedNode.value = node
      console.log('Selecting node:', node)

      // 建立Session连接
      const session = await establishNodeSession(node)
      selectedNodeSession.value = session.sessionId
      selectedNodeSource.value = session.source
      
      // 将配置信息存储到节点对象中
      if (session.config) {
        selectedNode.value.config = session.config
        console.log('Node config stored:', selectedNode.value.name, selectedNode.value.config)
      }
      
      console.log('Node session ready for:', node.name, 'SessionId:', session.sessionId)
    } catch (error) {
      console.error('Failed to select node:', error)
      selectedNode.value = null
      selectedNodeSession.value = null
      selectedNodeSource.value = null
    }
  }

  // 为选定节点创建API请求
  const createNodeRequest = async (method, data = {}, signal = null) => {
    if (!selectedNode.value || !selectedNodeSession.value) {
      throw new Error('No node session available')
    }

    const targetNode = selectedNode.value
    const sessionId = selectedNodeSession.value

    // 如果选择的是当前节点，使用现有的appStore方法
    if (isCurrentNode(targetNode)) {
      const appStore = useAppStore()
      return appStore.requestMethod(method, data, signal)
    }

    // 对于其他节点，使用该节点的session ID
    const baseURL = targetNode.url

    let axiosConfig = {
      timeout: 1000 * 120,
      headers: {
        'session': sessionId,
        'Content-Type': 'application/json'
      }
    }

    if (signal != null) {
      axiosConfig.signal = signal
    }

    const _axios = axios.create(axiosConfig)

    return new Promise((resolve, reject) => {
      _axios
        .get(`${baseURL}/method/${method}`, { params: data })
        .then((response) => {
          if (response.data && response.data.success) {
            resolve(response.data)
            return
          }
          reject(response)
        })
        .catch((error) => {
          console.error('Node request error:', error)
          reject(error)
        })
    })
  }

  // 获取选定节点的EventSource
  const getNodeEventSource = () => {
    if (!selectedNode.value || !selectedNodeSource.value) {
      throw new Error('No node session available')
    }
    return selectedNodeSource.value
  }

  // computed properties
  const availableNodes = computed(() => nodes.value)
  const hasSelectedNode = computed(() => selectedNode.value !== null)
  const selectedNodeName = computed(() => selectedNode.value?.name || '')
  const selectedNodeLocation = computed(() => selectedNode.value?.location || '')
  const hasNodeSession = computed(() => selectedNodeSession.value !== null)

  return {
    // 状态
    nodes,
    selectedNode,
    currentNode,
    latencies,
    loading,
    pingStates,
    selectedNodeSession,

    // computed
    availableNodes,
    hasSelectedNode,
    selectedNodeName,
    selectedNodeLocation,
    hasNodeSession,

    // 方法
    getNodeKey,
    isCurrentNode,
    getStatusByLatency,
    getStatusText,
    fetchNodes,
    testNodeLatency,
    testAllLatencies,
    pingSingleNode,
    selectNode,
    createNodeRequest,
    getNodeEventSource,
    cleanupNodeSession
  }
})