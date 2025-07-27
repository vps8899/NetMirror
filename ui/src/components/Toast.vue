<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useAppStore } from '@/stores/app'
import { 
  XMarkIcon, 
  CheckCircleIcon, 
  ExclamationTriangleIcon, 
  InformationCircleIcon,
  XCircleIcon
} from '@heroicons/vue/24/outline'

const appStore = useAppStore()

const getIcon = (type) => {
  switch (type) {
    case 'success': return CheckCircleIcon
    case 'warning': return ExclamationTriangleIcon
    case 'error': return XCircleIcon
    case 'info':
    default: return InformationCircleIcon
  }
}

const getColorClasses = (type) => {
  switch (type) {
    case 'success': 
      return 'bg-green-500 border-green-400 text-white'
    case 'warning': 
      return 'bg-yellow-500 border-yellow-400 text-white'
    case 'error': 
      return 'bg-red-500 border-red-400 text-white'
    case 'info':
    default: 
      return 'bg-blue-500 border-blue-400 text-white'
  }
}
</script>

<template>
  <div class="fixed top-4 right-4 z-[9999] space-y-2">
    <TransitionGroup
      name="toast"
      tag="div"
      class="space-y-2"
    >
      <div
        v-for="toast in appStore.toasts"
        :key="toast.id"
        :class="[
          'flex items-center p-4 rounded-lg shadow-lg border backdrop-blur-sm max-w-sm',
          getColorClasses(toast.type)
        ]"
      >
        <component 
          :is="getIcon(toast.type)" 
          class="w-5 h-5 mr-3 flex-shrink-0"
        />
        <div class="flex-1 text-sm font-medium">
          {{ toast.message }}
        </div>
        <button
          @click="appStore.removeToast(toast.id)"
          class="ml-3 p-1 rounded-md hover:bg-white/20 transition-colors flex-shrink-0"
        >
          <XMarkIcon class="w-4 h-4" />
        </button>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-enter-active,
.toast-leave-active {
  transition: all 0.3s ease;
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100%);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100%);
}

.toast-move {
  transition: transform 0.3s ease;
}
</style>