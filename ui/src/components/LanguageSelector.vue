<script setup>
import { ref, computed } from 'vue'
import { ChevronDownIcon, GlobeAltIcon } from '@heroicons/vue/24/outline'
import { useMotion } from '@vueuse/motion'

const { apply } = useMotion()

const props = defineProps({
  currentLang: String,
  langList: Array
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
</script>

<template>
  <div class="relative">
    <button
      @click="isOpen = !isOpen"
      class="inline-flex items-center space-x-2 px-3 py-2 bg-white/50 dark:bg-gray-700/50 hover:bg-white/80 dark:hover:bg-gray-700/80 rounded-xl transition-all duration-200"
    >
      <GlobeAltIcon class="w-4 h-4 text-gray-600 dark:text-gray-400" />
      <span class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ currentLangLabel }}</span>
      <ChevronDownIcon 
        class="w-4 h-4 text-gray-500 transition-transform duration-200"
        :class="{ 'rotate-180': isOpen }"
      />
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
        class="absolute left-0 mt-2 w-48 bg-white/80 dark:bg-gray-800/80 backdrop-blur-lg rounded-xl shadow-xl border border-white/20 dark:border-gray-700/50 py-2 z-50"
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
