<script setup>
import { ref } from 'vue'
import { ClipboardDocumentIcon, CheckIcon } from '@heroicons/vue/24/outline'
import { useMotion } from '@vueuse/motion'

const props = defineProps({
  value: String,
  text: Boolean,
  hideMessage: Boolean
})

const isClicked = ref(false)
const buttonRef = ref()

const { apply } = useMotion(buttonRef, {
  initial: { scale: 1 },
  tap: { scale: 0.9 }
})

const copy = async (value) => {
  try {
    await navigator.clipboard.writeText(value)
  } catch (error) {
    const textarea = document.createElement('textarea')
    document.body.appendChild(textarea)
    textarea.textContent = value
    textarea.select()
    document?.execCommand('copy')
    textarea.remove()
  }
  
  isClicked.value = true
  setTimeout(() => {
    isClicked.value = false
  }, 2000)
}
</script>

<template>
  <button
    ref="buttonRef"
    @click="copy(props.value)"
    class="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 transition-all duration-200 group"
    :class="{ 'bg-green-100 dark:bg-green-900/30': isClicked }"
  >
    <Transition
      enter-active-class="transition-all duration-200"
      enter-from-class="opacity-0 scale-75"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition-all duration-200"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-75"
    >
      <CheckIcon v-if="isClicked" class="w-4 h-4 text-green-600 dark:text-green-400" />
      <ClipboardDocumentIcon v-else class="w-4 h-4 text-gray-600 dark:text-gray-400 group-hover:text-gray-700 dark:group-hover:text-gray-300" />
    </Transition>
  </button>
</template>
