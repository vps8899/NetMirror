import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import axios from 'axios'

export const useNodeAdminStore = defineStore('nodeAdmin', () => {
  // State
  const nodes = ref([])
  const apiKey = ref('')
  const loading = ref(false)
  const error = ref(null)

  // Getters
  const isAuthenticated = computed(() => !!apiKey.value)

  // Load API key from localStorage on store initialization
  const loadStoredApiKey = () => {
    const stored = localStorage.getItem('admin_api_key')
    if (stored) {
      apiKey.value = stored
    }
  }

  // Save API key to localStorage
  const saveApiKey = (key) => {
    apiKey.value = key
    localStorage.setItem('admin_api_key', key)
  }

  // Remove API key from localStorage
  const clearApiKey = () => {
    apiKey.value = ''
    localStorage.removeItem('admin_api_key')
  }

  // Create axios instance with API key
  const createAuthenticatedAxios = () => {
    return axios.create({
      headers: {
        'X-Api-Key': apiKey.value
      }
    })
  }

  // Authenticate with API key
  const authenticate = async (key) => {
    loading.value = true
    error.value = null
    
    try {
      // Test the API key by trying to fetch nodes with admin auth
      const testAxios = axios.create({
        headers: {
          'X-Api-Key': key
        }
      })
      
      // Make a test request to public endpoint with admin auth
      // This tests auth and gets nodes in one request
      const response = await testAxios.get('/nodes')
      
      // If successful, save the key and store the nodes
      saveApiKey(key)
      nodes.value = response.data.nodes || []
      
      return true
    } catch (err) {
      error.value = err.response?.data?.error || 'Authentication failed'
      clearApiKey()
      throw err
    } finally {
      loading.value = false
    }
  }

  // Logout
  const logout = () => {
    clearApiKey()
    nodes.value = []
    error.value = null
  }

  // Fetch all nodes (uses authenticated request if available)
  const fetchNodes = async () => {
    loading.value = true
    error.value = null
    
    try {
      let response
      if (isAuthenticated.value) {
        // Use authenticated request to get full node details with IDs
        const adminAxios = createAuthenticatedAxios()
        response = await adminAxios.get('/nodes')
      } else {
        // Use public request for environment-only nodes
        response = await axios.get('/nodes')
      }
      
      nodes.value = response.data.nodes || []
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to fetch nodes'
      throw err
    } finally {
      loading.value = false
    }
  }

  // Create new node
  const createNode = async (nodeData) => {
    if (!isAuthenticated.value) {
      throw new Error('Not authenticated')
    }
    
    loading.value = true
    error.value = null
    
    try {
      const adminAxios = createAuthenticatedAxios()
      await adminAxios.post('/api/admin/nodes', nodeData)
      
      // Refresh nodes list
      await fetchNodes()
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to create node'
      throw err
    } finally {
      loading.value = false
    }
  }

  // Update existing node
  const updateNode = async (nodeId, nodeData) => {
    if (!isAuthenticated.value) {
      throw new Error('Not authenticated')
    }
    
    loading.value = true
    error.value = null
    
    try {
      const adminAxios = createAuthenticatedAxios()
      await adminAxios.put(`/api/admin/nodes/${nodeId}`, nodeData)
      
      // Refresh nodes list
      await fetchNodes()
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to update node'
      throw err
    } finally {
      loading.value = false
    }
  }

  // Delete node
  const deleteNode = async (nodeId) => {
    if (!isAuthenticated.value) {
      throw new Error('Not authenticated')
    }
    
    loading.value = true
    error.value = null
    
    try {
      const adminAxios = createAuthenticatedAxios()
      await adminAxios.delete(`/api/admin/nodes/${nodeId}`)
      
      // Refresh nodes list
      await fetchNodes()
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to delete node'
      throw err
    } finally {
      loading.value = false
    }
  }

  // Get single node details
  const getNode = async (nodeId) => {
    if (!isAuthenticated.value) {
      throw new Error('Not authenticated')
    }
    
    try {
      const adminAxios = createAuthenticatedAxios()
      const response = await adminAxios.get(`/api/admin/nodes/${nodeId}`)
      return response.data.node
    } catch (err) {
      error.value = err.response?.data?.error || 'Failed to fetch node'
      throw err
    }
  }

  // Test node connectivity
  const testNodeConnectivity = async (nodeUrl) => {
    try {
      const timestamp = Date.now()
      const response = await axios.get(`${nodeUrl}/nodes/latency?timestamp=${timestamp}`, {
        timeout: 5000
      })
      
      if (response.data.success) {
        return {
          success: true,
          latency: response.data.latency,
          status: response.data.status
        }
      } else {
        return {
          success: false,
          error: 'Server returned error'
        }
      }
    } catch (err) {
      return {
        success: false,
        error: err.message || 'Connection failed'
      }
    }
  }

  // Initialize store
  loadStoredApiKey()

  return {
    // State
    nodes,
    apiKey,
    loading,
    error,
    
    // Getters
    isAuthenticated,
    
    // Actions
    authenticate,
    logout,
    fetchNodes,
    createNode,
    updateNode,
    deleteNode,
    getNode,
    testNodeConnectivity
  }
})