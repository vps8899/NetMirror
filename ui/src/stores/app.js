import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import axios from 'axios'
import { formatBytes } from '@/helper/unit'

export const useAppStore = defineStore('app', () => {
  const source = ref()
  const sessionId = ref()
  const connecting = ref(true)
  const config = ref()
  const drawerWidth = ref()
  const memoryUsage = ref()
  
  // Toast management
  const toasts = ref([])
  let toastIdCounter = 0
  
  // Theme and language settings with persistence
  const theme = ref(localStorage.getItem('theme') || 'light')
  const language = ref(localStorage.getItem('language') || 'en-US')
  
  // Watch theme changes and persist
  const setTheme = (newTheme) => {
    theme.value = newTheme
    localStorage.setItem('theme', newTheme)
    document.documentElement.classList.toggle('dark', newTheme === 'dark')
  }
  
  // Watch language changes and persist
  const setLanguage = (newLang) => {
    language.value = newLang
    localStorage.setItem('language', newLang)
  }
  
  // Initialize theme on load
  if (theme.value === 'dark') {
    document.documentElement.classList.add('dark')
  }
  
  let timer = ''

  const handleResize = () => {
    let width = window.innerWidth
    if (width > 800) {
      drawerWidth.value = 800
    } else {
      drawerWidth.value = width
    }
  }
  window.addEventListener('resize', handleResize)
  handleResize()

  let initializePromise = null

  const reconnectEventSource = () => {
    clearTimeout(timer)
    setTimeout(() => {
      // Reset promise to allow re-initialization on reconnect
      initializePromise = null
      initialize()
    }, 1000)
  }

  const setupEventSource = () => {
    return new Promise((resolve, reject) => {
      connecting.value = true
      const eventSource = new EventSource('./session')

      eventSource.addEventListener('SessionId', (e) => {
        sessionId.value = e.data
        console.log('session', e.data)
        resolve()
      })

      eventSource.addEventListener('Config', (e) => {
        config.value = JSON.parse(e.data)
        connecting.value = false
      })

      eventSource.addEventListener('MemoryUsage', (e) => {
        memoryUsage.value = formatBytes(e.data)
      })

      eventSource.onerror = function (e) {
        eventSource.close()
        connecting.value = true
        console.log('SSE disconnected')
        reconnectEventSource()
        reject(new Error('SSE connection failed'))
      }
      source.value = eventSource
    })
  }

  const initialize = () => {
    if (!initializePromise) {
      initializePromise = setupEventSource()
    }
    return initializePromise
  }

  const requestMethod = (method, data = {}, signal = null) => {
    let axiosConfig = {
      timeout: 1000 * 120, // 请求超时时间
      headers: {
        session: sessionId.value
      }
    }

    if (signal != null) {
      axiosConfig.signal = signal
    }

    const _axios = axios.create(axiosConfig)

    return new Promise((resolve, reject) => {
      _axios
        .get('./method/' + method, { params: data })
        .then((response) => {
          if (response.data.success) {
            resolve(response.data)
            return
          }
          reject(response)
        })
        .catch((error) => {
          if (error.code == 'ERR_CANCELED') {
            reject(error)
            return
          }
          
          // Handle 400 Bad Request errors
          if (error.response && error.response.status === 400) {
            showToast('输入参数无效，请检查您的输入', 'error')
          }
          
          console.error(error)
          reject(error)
        })
    })
  }

  // Toast methods
  const showToast = (message, type = 'info', duration = 5000) => {
    const id = ++toastIdCounter
    const toast = {
      id,
      message,
      type,
      timestamp: Date.now()
    }
    
    toasts.value.push(toast)
    
    // Auto remove after duration
    if (duration > 0) {
      setTimeout(() => {
        removeToast(id)
      }, duration)
    }
    
    return id
  }

  const removeToast = (id) => {
    const index = toasts.value.findIndex(toast => toast.id === id)
    if (index > -1) {
      toasts.value.splice(index, 1)
    }
  }

  const clearToasts = () => {
    toasts.value = []
  }

  return {
    //vars
    source,
    sessionId,
    connecting,
    config,
    drawerWidth,
    memoryUsage,
    theme,
    language,
    toasts,

    //methods
    initialize,
    requestMethod,
    setTheme,
    setLanguage,
    showToast,
    removeToast,
    clearToasts
  }
})
