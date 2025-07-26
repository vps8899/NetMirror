<script setup>
import { Sun, Moon } from 'lucide-vue-next'
import { useMotion } from '@vueuse/motion'
import { ref } from 'vue'

const buttonRef = ref()
const { apply } = useMotion(buttonRef, {
  initial: { scale: 1 },
  press: { scale: 0.95 },
  hovered: { scale: 1.1 }
})

defineProps({
  isDark: Boolean
})

defineEmits(['toggle'])
</script>

<template>
  <button
    ref="buttonRef"
    @click="$emit('toggle')"
    class="relative inline-flex items-center justify-center w-10 h-10 rounded-xl bg-white/50 dark:bg-gray-700/50 hover:bg-white/80 dark:hover:bg-gray-700/80 transition-all duration-200"
    aria-label="Toggle theme"
  >
    <span class="sr-only">Toggle theme</span>
    <Transition
      enter-active-class="transition-all duration-300 ease-out-back"
      enter-from-class="opacity-0 rotate-90 scale-50"
      enter-to-class="opacity-100 rotate-0 scale-100"
      leave-active-class="transition-all duration-300 ease-in-back"
      leave-from-class="opacity-100 rotate-0 scale-100"
      leave-to-class="opacity-0 -rotate-90 scale-50"
      mode="out-in"
    >
      <Sun v-if="isDark" class="w-5 h-5 text-amber-500" key="sun" />
      <Moon v-else class="w-5 h-5 text-gray-700" key="moon" />
    </Transition>
  </button>
</template>

<style>
.ease-out-back {
  transition-timing-function: cubic-bezier(0.34, 1.56, 0.64, 1);
}
.ease-in-back {
  transition-timing-function: cubic-bezier(0.68, -0.6, 0.32, 1.6);
}
</style>
