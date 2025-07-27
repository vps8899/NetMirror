<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  currentLang: String,
  langList: Array,
  showLabel: {
    type: Boolean,
    default: true
  }
})

const emit = defineEmits(['change'])

const isOpen = ref(false)
const dropdownRef = ref()

const currentLangLabel = computed(() => {
  const lang = props.langList.find(l => l.value === props.currentLang)
  return lang?.label || 'English'
})

const selectLanguage = (langValue) => {
  emit('change', langValue)
  isOpen.value = false
}

// Close dropdown when clicking outside
const closeDropdown = (event) => {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target)) {
    isOpen.value = false
  }
}

// Add/remove event listener for clicking outside
onMounted(() => {
  document.addEventListener('click', closeDropdown)
})

onUnmounted(() => {
  document.removeEventListener('click', closeDropdown)
})
</script>

<template>
  <div class="relative">
    <button
      @click="isOpen = !isOpen"
      class="inline-flex items-center justify-center transition-all duration-200"
      :class="showLabel ? 'space-x-2 px-3 py-2 bg-white/50 dark:bg-gray-700/50 hover:bg-white/80 dark:hover:bg-gray-700/80 rounded-xl' : 'w-full h-full hover:bg-gray-100 dark:hover:bg-gray-600 rounded-xl'"
    >
      <!-- Globe Icon -->
      <svg class="w-6 h-6 text-gray-600 dark:text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
      </svg>
      <span v-if="showLabel" class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ currentLangLabel }}</span>
      <!-- Chevron Down Icon -->
      <svg 
        v-if="showLabel"
        class="w-4 h-4 text-gray-500 transition-transform duration-200"
        :class="{ 'rotate-180': isOpen }"
        fill="none" 
        stroke="currentColor" 
        viewBox="0 0 24 24"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <Transition
      enter-active-class="transition-all duration-200 ease-out"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition-all duration-150 ease-in"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div
        v-if="isOpen"
        ref="dropdownRef"
        class="absolute bottom-full mb-2 w-48 bg-white/80 dark:bg-gray-800/80 backdrop-blur-lg rounded-xl shadow-xl border border-white/20 dark:border-gray-700/50 py-2 z-50"
        :class="showLabel ? 'left-0' : 'right-0'"
      >
        <button
          v-for="lang in langList"
          :key="lang.value"
          @click="selectLanguage(lang.value)"
          class="w-full px-4 py-2 text-left text-sm hover:bg-gray-50/50 dark:hover:bg-gray-700/50 transition-colors duration-150"
          :class="{ 'bg-primary-50 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400': currentLang === lang.value }"
        >
          {{ lang.label }}
        </button>
      </div>
    </Transition>
  </div>
</template>
