import { fileURLToPath, URL } from "node:url"
import { defineConfig } from "vite"
import vue from "@vitejs/plugin-vue"
import AutoImport from "unplugin-auto-import/vite"
import Components from "unplugin-vue-components/vite"
import fs from "node:fs"
import path from "node:path"

export default defineConfig(({ command, mode }) => {
  const isDev = command === "serve"
  const isProd = mode === "production"

  return {
    base: "./",

    // Development server configuration
    server: {
      host: "0.0.0.0",
      port: 3000,
      proxy: {
        "/session": {
          target: "http://127.0.0.1:8080",
          ws: true,
          changeOrigin: true,
        },
        "/method": {
          target: "http://127.0.0.1:8080",
          ws: true,
          changeOrigin: true,
        },
      },
    },

    // Build configuration
    build: {
      target: "es2015",
      outDir: "dist",
      assetsDir: "assets",
      sourcemap: !isProd,
      minify: isProd ? "terser" : false,

      // Optimize bundle size
      rollupOptions: {
        output: {
          manualChunks: {
            // Vendor chunks
            "vendor-vue": ["vue", "pinia"],
            "vendor-ui": ["@vueuse/core", "@vueuse/motion"],
            "vendor-charts": ["vue3-apexcharts", "apexcharts"],
            "vendor-terminal": ["xterm", "@xterm/addon-fit"],
            "vendor-utils": ["axios", "vue-i18n"],
          },
          // Optimize chunk file names
          chunkFileNames: (chunkInfo) => {
            const facadeModuleId = chunkInfo.facadeModuleId
            if (facadeModuleId) {
              const name = path.basename(facadeModuleId, path.extname(facadeModuleId))
              return `js/${name}-[hash].js`
            }
            return "js/[name]-[hash].js"
          },
          entryFileNames: "js/[name]-[hash].js",
          assetFileNames: (assetInfo) => {
            const info = assetInfo.name.split(".")
            const ext = info[info.length - 1]
            if (/\.(css)$/.test(assetInfo.name)) {
              return `css/[name]-[hash].${ext}`
            }
            if (/\.(png|jpe?g|gif|svg|ico|webp)$/.test(assetInfo.name)) {
              return `images/[name]-[hash].${ext}`
            }
            if (/\.(woff2?|eot|ttf|otf)$/.test(assetInfo.name)) {
              return `fonts/[name]-[hash].${ext}`
            }
            return `assets/[name]-[hash].${ext}`
          },
        },
      },

      // Terser options for production
      terserOptions: isProd
        ? {
            compress: {
              drop_console: true,
              drop_debugger: true,
            },
          }
        : undefined,
    },

    // Path resolution
    resolve: {
      alias: {
        "@": fileURLToPath(new URL("./src", import.meta.url)),
      },
    },

    // CSS configuration
    css: {
      devSourcemap: isDev,
      preprocessorOptions: {
        scss: {
          additionalData: `@import "@/styles/variables.scss";`,
        },
      },
    },

    // Plugin configuration
    plugins: [
      vue({
        template: {
          compilerOptions: {
            // Optimize template compilation
            hoistStatic: true,
            cacheHandlers: true,
          },
        },
      }),

      // Auto import composables and utilities
      AutoImport({
        imports: [
          "vue",
          "@vueuse/core",
          {
            "@vueuse/motion": ["useMotion"],
          },
          "pinia",
          "vue-i18n",
        ],
        dts: true,
        eslintrc: {
          enabled: true,
        },
      }),

      // Auto import components
      Components({
        dts: true,
        resolvers: [],
        directoryAsDirectory: true,
      }),

      // Custom plugin for build-time file operations
      {
        name: "build-assets",
        buildStart(options) {
          if (command === "build") {
            const dirPath = path.join(__dirname, "public")
            const fileBuildRequired = {
              "speedtest_worker.js": "../speedtest/speedtest_worker.js",
            }

            // Ensure public directory exists
            if (!fs.existsSync(dirPath)) {
              fs.mkdirSync(dirPath, { recursive: true })
            }

            for (const dest in fileBuildRequired) {
              const source = fileBuildRequired[dest]
              const sourcePath = path.join(dirPath, source)
              const destPath = path.join(dirPath, dest)

              try {
                // Remove existing file
                if (fs.existsSync(destPath)) {
                  fs.unlinkSync(destPath)
                }

                // Copy source to destination
                if (fs.existsSync(sourcePath)) {
                  fs.copyFileSync(sourcePath, destPath)
                  console.log(`✓ Copied ${source} to ${dest}`)
                } else {
                  console.warn(`⚠ Source file not found: ${sourcePath}`)
                }
              } catch (error) {
                console.error(`✗ Failed to copy ${source} to ${dest}:`, error.message)
              }
            }
          }
        },
      },

      // Bundle analyzer for production builds
      ...(isProd && process.env.ANALYZE
        ? [
            {
              name: "bundle-analyzer",
              generateBundle() {
                // This would integrate with rollup-plugin-visualizer if needed
                console.log("📊 Bundle analysis available")
              },
            },
          ]
        : []),
    ],

    // Optimization
    optimizeDeps: {
      include: ["vue", "pinia", "@vueuse/core", "@vueuse/motion", "axios", "vue-i18n", "vue3-apexcharts", "apexcharts"],
      exclude: [
        // Exclude large dependencies that should be loaded dynamically
      ],
    },

    // Define global constants
    define: {
      __VUE_OPTIONS_API__: false,
      __VUE_PROD_DEVTOOLS__: false,
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version || "1.0.0"),
      __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
    },

    // Experimental features
    experimental: {
      renderBuiltUrl(filename, { hostType }) {
        if (hostType === "js") {
          return { js: `/${filename}` }
        } else {
          return { relative: true }
        }
      },
    },
  }
})
