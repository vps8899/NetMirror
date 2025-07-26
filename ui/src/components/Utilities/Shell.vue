<script setup>
import { ref, onMounted, onUnmounted, toRaw } from 'vue'
import 'xterm/css/xterm.css'
import { Terminal } from 'xterm'
import { FitAddon } from '@xterm/addon-fit'
import { useAppStore } from '@/stores/app'

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
const terminalRef = ref()
const fitAddon = new FitAddon()
const emit = defineEmits(['closed'])
let websocket
let buffer = []

const flushToTerminal = () => {
  if (buffer.length > 0) {
    terminal.write(new Uint8Array(buffer.shift()), () => {
      flushToTerminal()
    })
  }
}

const updateWindowSize = () => {
  fitAddon.fit()
  websocket.send(new TextEncoder().encode('2' + terminal.rows + ';' + terminal.cols))
}

let resizeTimer
const handleResize = () => {
  clearTimeout(resizeTimer)
  resizeTimer = setTimeout(() => {
    updateWindowSize()
  }, 100)
}

onMounted(() => {
  terminal.loadAddon(fitAddon)
  terminal.open(toRaw(terminalRef.value))
  fitAddon.fit()
  const url = new URL(location.href)
  const protocol = url.protocol == 'http:' ? 'ws:' : 'wss:'
  websocket = new WebSocket(
    protocol + '//' + url.host + url.pathname + 'session/' + useAppStore().sessionId + '/shell'
  )
  websocket.binaryType = 'arraybuffer'
  websocket.addEventListener('message', (event) => {
    buffer.push(event.data)
    flushToTerminal()
  })

  websocket.addEventListener('open', (event) => {
    window.addEventListener('resize', handleResize)

    handleResize()
    setTimeout(handleResize, 1000)
  })

  websocket.addEventListener('close', (event) => {
    console.log(event)
    emit('closed')
  })

  terminal.onData((data) => {
    websocket.send(new TextEncoder().encode('1' + data))
  })
  fitAddon.fit()
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (websocket) {
    websocket.close()
  }
  if (terminal) {
    terminal.dispose()
  }
})
</script>

<template>
  <div ref="terminalRef" class="terminal" style="flex-grow: 1; height: 100%" />
</template>

<style>
div:has(> div.terminal) {
  padding: 0px !important;
}
</style>