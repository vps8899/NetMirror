<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useMotion } from '@vueuse/motion'
import { useAppStore } from '@/stores/app'
import { CommandLineIcon } from '@heroicons/vue/24/outline'
import 'xterm/css/xterm.css'
import { Terminal } from 'xterm'
import { FitAddon } from '@xterm/addon-fit'
import { toRaw } from 'vue'

const emit = defineEmits(['closed'])

const appStore = useAppStore()
const terminalRef = ref()
const containerRef = ref()
const fitAddon = new FitAddon()
const isConnected = ref(false)
const connectionStatus = ref('Connecting...')

let websocket
let buffer = []
let resizeTimer

const { apply } = useMotion(containerRef, {
  initial: { opacity: 0, scale: 0.95 },
  enter: { opacity: 1, scale: 1, transition: { duration: 300 } }
})

const flushToTerminal = () => {
  if (buffer.length > 0) {
    terminal.write(new Uint8Array(buffer.shift()), () => {
      flushToTerminal()
    })
  }
}

const updateWindowSize = () => {
  fitAddon.fit()
  if (websocket && websocket.readyState === WebSocket.OPEN) {
    websocket.send(new TextEncoder().encode('2' + terminal.rows + ';' + terminal.cols))
  }
}

const handleResize = () => {
  clearTimeout(resizeTimer)
  resizeTimer = setTimeout(() => {
    updateWindowSize()
  }, 100)
}

const connectWebSocket = () => {
  const url = new URL(location.href)
  const protocol = url.protocol === 'https:' ? 'wss:' : 'ws:'
  const wsUrl = `${protocol}//${url.host}/session/${appStore.sessionId}/shell`
  
  console.log('Connecting to WebSocket:', wsUrl)
  console.log('Session ID:', appStore.sessionId)
  
  websocket = new WebSocket(wsUrl)
  websocket.binaryType = 'arraybuffer'
  
  websocket.addEventListener('open', () => {
    console.log('WebSocket connected successfully')
    isConnected.value = true
    connectionStatus.value = 'Connected'
    terminal.clear()
    terminal.writeln('\x1b[1;32m╭─────────────────────────────────────────────────────────────╮\x1b[0m')
    terminal.writeln('\x1b[1;32m│\x1b[0m \x1b[1;36mWelcome to ALS Interactive Shell\x1b[0m                        \x1b[1;32m│\x1b[0m')
    terminal.writeln('\x1b[1;32m│\x1b[0m \x1b[90mLimited command set available for security\x1b[0m               \x1b[1;32m│\x1b[0m')
    terminal.writeln('\x1b[1;32m╰─────────────────────────────────────────────────────────────╯\x1b[0m')
    terminal.writeln('')
    
    window.addEventListener('resize', handleResize)
    handleResize()
    setTimeout(handleResize, 1000)
  })
  
  websocket.addEventListener('message', (event) => {
    buffer.push(event.data)
    flushToTerminal()
  })
  
  websocket.addEventListener('close', (event) => {
    console.log('WebSocket closed:', event.code, event.reason)
    isConnected.value = false
    if (event.code === 1000) {
      connectionStatus.value = 'Disconnected'
      terminal.writeln('\r\n\x1b[1;33mConnection closed normally\x1b[0m')
    } else {
      connectionStatus.value = 'Connection lost'
      terminal.writeln('\r\n\x1b[1;31mConnection lost unexpectedly\x1b[0m')
    }
    emit('closed')
  })
  
  websocket.addEventListener('error', (error) => {
    console.error('WebSocket error:', error)
    connectionStatus.value = 'Connection error'
    terminal.writeln('\r\n\x1b[1;31mWebSocket connection error\x1b[0m')
  })
  
  terminal.onData((data) => {
    if (websocket && websocket.readyState === WebSocket.OPEN) {
      websocket.send(new TextEncoder().encode('1' + data))
    }
  })
}

const terminal = new Terminal({
  theme: {
    background: '#111827',
    foreground: '#d1d5db',
    cursor: '#60a5fa',
    cursorAccent: '#1e40af',
    selectionBackground: '#374151',
    black: '#111827',
    red: '#ef4444',
    green: '#22c55e',
    yellow: '#f59e0b',
    blue: '#3b82f6',
    magenta: '#a855f7',
    cyan: '#06b6d4',
    white: '#f9fafb',
    brightBlack: '#4b5563',
    brightRed: '#f87171',
    brightGreen: '#4ade80',
    brightYellow: '#fbbf24',
    brightBlue: '#60a5fa',
    brightMagenta: '#c084fc',
    brightCyan: '#22d3ee',
    brightWhite: '#ffffff'
  },
  fontFamily: 'JetBrains Mono, SF Mono, Monaco, Inconsolata, "Fira Code", "Fira Mono", "Droid Sans Mono", Consolas, "Source Code Pro", monospace',
  fontSize: 14,
  fontWeight: 400,
  fontWeightBold: 700,
  lineHeight: 1.4,
  cursorBlink: true,
  cursorStyle: 'block',
  scrollback: 1000,
  tabStopWidth: 4
})

onMounted(() => {
  terminal.loadAddon(fitAddon)
  terminal.open(toRaw(terminalRef.value))
  fitAddon.fit()
  apply()
  
  connectWebSocket()
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (websocket) {
    websocket.close()
  }
})
</script>

<template>
  <div ref="containerRef" class="h-full flex flex-col bg-gray-900 rounded-xl overflow-hidden border border-gray-700 shadow-2xl">
    <!-- Header -->
    <div class="flex items-center justify-between p-3 bg-gray-800 border-b border-gray-700 flex-shrink-0">
      <div class="flex items-center space-x-2">
        <div class="w-3 h-3 bg-red-500 rounded-full"></div>
        <div class="w-3 h-3 bg-yellow-500 rounded-full"></div>
        <div class="w-3 h-3 bg-green-500 rounded-full"></div>
      </div>
      <div class="flex items-center space-x-2 text-sm text-gray-300">
        <CommandLineIcon class="w-4 h-4" />
        <span>Interactive Shell</span>
      </div>
      <div class="flex items-center space-x-2">
        <div 
          class="w-2.5 h-2.5 rounded-full transition-colors"
          :class="isConnected ? 'bg-green-400' : 'bg-red-400'"
        ></div>
        <span class="text-xs text-gray-400">{{ connectionStatus }}</span>
      </div>
    </div>
    
    <!-- Terminal Container -->
    <div class="flex-1 bg-gray-900 relative overflow-hidden">
      <div ref="terminalRef" class="absolute inset-0 p-2"></div>
      
      <!-- Loading Overlay -->
      <div v-if="!isConnected" class="absolute inset-0 bg-gray-900/80 backdrop-blur-sm flex items-center justify-center">
        <div class="text-center">
          <div class="w-8 h-8 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p class="text-white font-medium">{{ connectionStatus }}</p>
        </div>
      </div>
    </div>
    
    <!-- Footer -->
    <div class="px-4 py-1.5 bg-gray-800 border-t border-gray-700 flex-shrink-0">
      <div class="flex items-center justify-between text-xs text-gray-400">
        <span>Limited shell environment • Type 'help' for available commands</span>
        <span v-if="isConnected">{{ terminal.rows }}×{{ terminal.cols }}</span>
      </div>
    </div>
  </div>
</template>
