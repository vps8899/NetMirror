<template>
  <div class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
    <div class="relative top-20 mx-auto p-5 border w-full max-w-md shadow-lg rounded-md bg-white dark:bg-gray-800">
      <div class="mt-3">
        <h3 class="text-lg font-medium text-gray-900 dark:text-gray-100 mb-4">
          {{ isEdit ? 'Edit Node' : 'Add New Node' }}
        </h3>
        
        <form @submit.prevent="handleSubmit" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Node Name *
            </label>
            <input
              v-model="formData.name"
              type="text"
              required
              placeholder="e.g., London Node"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            >
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Display name for this node
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              Location *
            </label>
            <input
              v-model="formData.location"
              type="text"
              required
              placeholder="e.g., London, UK"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            >
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Geographic location of the node
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
              URL *
            </label>
            <input
              v-model="formData.url"
              type="url"
              required
              placeholder="https://lg.example.com"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500 bg-white dark:bg-gray-700 text-gray-900 dark:text-gray-100"
            >
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Full URL including protocol (https://)
            </p>
          </div>

          <!-- Form Actions -->
          <div class="flex justify-end space-x-3 mt-6 pt-4 border-t border-gray-200 dark:border-gray-700">
            <button
              type="button"
              @click="$emit('close')"
              class="px-4 py-2 bg-white dark:bg-gray-700 text-gray-800 dark:text-gray-200 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-gray-500"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="!isFormValid || saving"
              class="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span v-if="saving" class="flex items-center">
                <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                {{ isEdit ? 'Updating...' : 'Creating...' }}
              </span>
              <span v-else>
                {{ isEdit ? 'Update Node' : 'Create Node' }}
              </span>
            </button>
          </div>
        </form>

        <!-- URL Validation Tips -->
        <div class="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700 rounded-md">
          <h4 class="text-sm font-medium text-blue-800 dark:text-blue-300 mb-2">URL Requirements:</h4>
          <ul class="text-xs text-blue-700 dark:text-blue-400 space-y-1">
            <li>• Must include protocol (https:// recommended)</li>
            <li>• Should be accessible from this server</li>
            <li>• Node must run the same Looking Glass software</li>
            <li>• CORS must be properly configured</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  node: {
    type: Object,
    default: null
  },
  isEdit: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['close', 'save'])

const saving = ref(false)
const formData = ref({
  name: '',
  location: '',
  url: ''
})

// Initialize form data
if (props.node) {
  formData.value = {
    name: props.node.name || '',
    location: props.node.location || '',
    url: props.node.url || ''
  }
}

const isFormValid = computed(() => {
  return formData.value.name.trim() && 
         formData.value.location.trim() && 
         formData.value.url.trim() &&
         isValidUrl(formData.value.url)
})

const isValidUrl = (url) => {
  try {
    new URL(url)
    return true
  } catch {
    return false
  }
}

const handleSubmit = async () => {
  if (!isFormValid.value) return
  
  saving.value = true
  try {
    // Clean URL - remove trailing slash
    const cleanUrl = formData.value.url.replace(/\/$/, '')
    
    emit('save', {
      name: formData.value.name.trim(),
      location: formData.value.location.trim(),
      url: cleanUrl
    })
  } finally {
    saving.value = false
  }
}

// Auto-focus first input when modal opens
watch(() => props.node, () => {
  if (props.node) {
    formData.value = {
      name: props.node.name || '',
      location: props.node.location || '',
      url: props.node.url || ''
    }
  }
}, { immediate: true })
</script>