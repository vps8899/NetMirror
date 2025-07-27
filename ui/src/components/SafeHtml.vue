<script setup>
import { computed } from 'vue'
import DOMPurify from 'dompurify'
import Markdown from 'vue3-markdown-it'

const props = defineProps({
  content: {
    type: String,
    required: true
  },
  contentType: {
    type: String,
    default: 'auto', // 'auto', 'markdown', 'html', 'iframe', 'text'
    validator: (value) => ['auto', 'markdown', 'html', 'iframe', 'text'].includes(value)
  },
  mode: {
    type: String,
    default: 'auto', // 向后兼容
    validator: (value) => ['auto', 'markdown', 'html', 'iframe', 'text'].includes(value)
  },
  allowHtml: {
    type: Boolean,
    default: true
  },
  iframeHeight: {
    type: String,
    default: '400px'
  }
})

// 优先使用 contentType，如果没有则使用 mode（向后兼容）
const actualContentType = computed(() => {
  return props.contentType !== 'auto' ? props.contentType : props.mode
})

// 检测内容类型
const detectedType = computed(() => {
  if (actualContentType.value !== 'auto') return actualContentType.value
  
  const content = props.content.trim()
  
  // 检测是否为URL（iframe）
  if (content.startsWith('http://') || content.startsWith('https://')) {
    const lowerURL = content.toLowerCase()
    // 如果是.md链接，应该在后端处理，这里不应该出现
    if (lowerURL.endsWith('.md')) {
      return 'markdown'
    }
    return 'iframe'
  }
  
  // 检测是否包含HTML标签（但不是Markdown中的HTML）
  const htmlTagPattern = /<(?!\/?(em|strong|i|b|u|code|pre|blockquote|ul|ol|li|h[1-6]|p|br|hr)\b)[^>]+>/i
  const hasComplexHtml = htmlTagPattern.test(content)
  
  // 检测Markdown特征
  const markdownPatterns = [
    /^#{1,6}\s/m,           // 标题
    /^\*\s|\d+\.\s/m,       // 列表
    /\[.*?\]\(.*?\)/,       // 链接
    /\*\*.*?\*\*|\*.*?\*/,  // 粗体/斜体
    /```[\s\S]*?```/,       // 代码块
    /^>\s/m                 // 引用
  ]
  
  const hasMarkdown = markdownPatterns.some(pattern => pattern.test(content))
  
  // 如果有复杂HTML且没有明显的Markdown特征，判断为HTML
  if (hasComplexHtml && !hasMarkdown) {
    return 'html'
  }
  
  if (hasMarkdown) {
    return 'markdown'
  }
  
  return 'text'
})

// 安全配置
const domPurifyConfig = {
  ALLOWED_TAGS: [
    'p', 'br', 'div', 'span', 'strong', 'b', 'em', 'i', 'u', 
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'ul', 'ol', 'li', 'blockquote', 'pre', 'code',
    'a', 'img', 'table', 'thead', 'tbody', 'tr', 'td', 'th',
    'hr', 'small', 'sub', 'sup'
  ],
  ALLOWED_ATTR: [
    'href', 'title', 'alt', 'src', 'width', 'height', 
    'class', 'id', 'target', 'rel'
  ],
  ALLOW_DATA_ATTR: false,
  ALLOW_UNKNOWN_PROTOCOLS: false,
  SANITIZE_DOM: true,
  KEEP_CONTENT: true,
  ADD_ATTR: {
    'a': {
      'rel': 'noopener noreferrer',
      'target': '_blank'
    }
  }
}

// 净化HTML内容
const sanitizedContent = computed(() => {
  if (!props.content) return ''
  
  if (detectedType.value === 'html') {
    return DOMPurify.sanitize(props.content, domPurifyConfig)
  }
  
  // Markdown、iframe、text 模式不需要额外净化
  return props.content
})

// iframe URL 安全性检查
const isSafeIframeUrl = computed(() => {
  if (detectedType.value !== 'iframe') return false
  
  const url = props.content.trim()
  try {
    const parsedUrl = new URL(url)
    // 只允许 http 和 https 协议
    return ['http:', 'https:'].includes(parsedUrl.protocol)
  } catch {
    return false
  }
})

// 用于显示的组件类型
const shouldUseMarkdown = computed(() => detectedType.value === 'markdown')
const shouldUseIframe = computed(() => detectedType.value === 'iframe' && isSafeIframeUrl.value)
const shouldUseHtml = computed(() => detectedType.value === 'html')
const shouldUseText = computed(() => detectedType.value === 'text')
</script>

<template>
  <div class="safe-html-content">
    <!-- Markdown 渲染 -->
    <Markdown 
      v-if="shouldUseMarkdown" 
      :source="sanitizedContent"
      class="prose prose-sm prose-primary max-w-none dark:prose-invert prose-headings:text-primary-700 dark:prose-headings:text-primary-300 prose-p:text-gray-700 dark:prose-p:text-gray-300 prose-a:text-primary-600 dark:prose-a:text-primary-400 prose-a:no-underline hover:prose-a:underline prose-strong:text-primary-700 dark:prose-strong:text-primary-300"
    />
    
    <!-- iframe 渲染 -->
    <div v-else-if="shouldUseIframe" class="iframe-container">
      <iframe
        :src="sanitizedContent"
        :style="{ height: iframeHeight }"
        class="w-full border border-primary-200 dark:border-primary-700/30 rounded-lg"
        frameborder="0"
        sandbox="allow-scripts allow-same-origin allow-popups allow-forms"
        loading="lazy"
        title="Sponsor Content"
      />
    </div>
    
    <!-- HTML 渲染 -->
    <div 
      v-else-if="shouldUseHtml"
      v-html="sanitizedContent"
      class="prose prose-sm prose-primary max-w-none dark:prose-invert prose-headings:text-primary-700 dark:prose-headings:text-primary-300 prose-p:text-gray-700 dark:prose-p:text-gray-300 prose-a:text-primary-600 dark:prose-a:text-primary-400 prose-a:no-underline hover:prose-a:underline prose-strong:text-primary-700 dark:prose-strong:text-primary-300"
    />
    
    <!-- 纯文本渲染 -->
    <div 
      v-else-if="shouldUseText"
      class="text-gray-700 dark:text-gray-300 whitespace-pre-wrap"
    >
      {{ sanitizedContent }}
    </div>
    
    <!-- 错误状态 -->
    <div v-else class="text-red-500 dark:text-red-400 text-sm">
      ⚠️ 无法渲染赞助信息：不支持的内容类型或不安全的URL
    </div>
    
    <!-- 调试信息（仅开发环境） -->
    <div v-if="$env?.DEV" class="mt-2 text-xs text-gray-500 border-t pt-2">
      检测类型: {{ detectedType }} | 模式: {{ actualContentType }} | 安全: {{ detectedType === 'iframe' ? isSafeIframeUrl : 'N/A' }}
    </div>
  </div>
</template>

<style scoped>
.safe-html-content :deep(a) {
  @apply transition-colors duration-200;
}

.safe-html-content :deep(img) {
  @apply max-w-full h-auto rounded-lg;
}

.safe-html-content :deep(table) {
  @apply w-full border-collapse;
}

.safe-html-content :deep(td),
.safe-html-content :deep(th) {
  @apply border border-gray-300 dark:border-gray-600 px-3 py-2;
}

.safe-html-content :deep(th) {
  @apply bg-gray-100 dark:bg-gray-700 font-semibold;
}

.iframe-container {
  @apply relative overflow-hidden rounded-lg;
}

.iframe-container iframe {
  @apply transition-opacity duration-300;
}

.iframe-container iframe:not([src]) {
  @apply opacity-50;
}
</style>