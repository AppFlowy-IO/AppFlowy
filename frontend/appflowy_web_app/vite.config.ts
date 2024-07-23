import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import svgr from 'vite-plugin-svgr';
import wasm from 'vite-plugin-wasm';
import { visualizer } from 'rollup-plugin-visualizer';
import usePluginImport from 'vite-plugin-importer';
import { totalBundleSize } from 'vite-plugin-total-bundle-size';
import path from 'path';
import istanbul from 'vite-plugin-istanbul';

const resourcesPath = path.resolve(__dirname, '../resources');
const isDev = process.env.NODE_ENV === 'development';
// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react(),
    wasm(),
    svgr({
      svgrOptions: {
        prettier: false,
        plugins: ['@svgr/plugin-svgo', '@svgr/plugin-jsx'],
        icon: true,
        svgoConfig: {
          multipass: true,
          plugins: [
            {
              name: 'preset-default',
              params: {
                overrides: {
                  removeViewBox: false,
                },
              },
            },
          ],
        },
        svgProps: {
          role: 'img',
        },
        replaceAttrValues: {
          '#333': 'currentColor',
        },
      },
    }),
    istanbul({
      cypress: true,
      requireEnv: false,
      include: ['src/**/*'],
      exclude: [
        '**/__tests__/**/*',
        'cypress/**/*',
        'node_modules/**/*',
        'src/application/services/tauri-services/**/*',
      ],
    }),
    usePluginImport({
      libraryName: '@mui/icons-material',
      libraryDirectory: '',
      camel2DashComponentName: false,
      style: false,
    }),
    process.env.ANALYZE_MODE
      ? visualizer({
          emitFile: true,
        })
      : undefined,
    process.env.ANALYZE_MODE
      ? totalBundleSize({
          fileNameRegex: /\.(js|css)$/,
          calculateGzip: false,
        })
      : undefined,
  ],
  // Vite options tailored for Tauri development and only applied in `tauri dev` or `tauri build`
  // prevent vite from obscuring rust errors
  clearScreen: false,
  // tauri expects a fixed port, fail if that port is not available
  server: {
    port: !!process.env.TAURI_PLATFORM ? 5173 : process.env.PORT ? parseInt(process.env.PORT) : 3000,
    strictPort: true,
    watch: {
      ignored: ['node_modules'],
    },
    cors: false,
  },
  envPrefix: ['AF', 'TAURI_'],
  esbuild: {
    pure: !isDev ? ['console.log', 'console.debug', 'console.info', 'console.trace'] : [],
  },
  build: !!process.env.TAURI_PLATFORM
    ? {
        // Tauri supports es2021
        target: process.env.TAURI_PLATFORM === 'windows' ? 'chrome105' : 'safari13',
        // don't minify for debug builds
        minify: !process.env.TAURI_DEBUG ? 'esbuild' : false,
        // produce sourcemaps for debug builds
        sourcemap: !!process.env.TAURI_DEBUG,
      }
    : {
        target: `esnext`,
        reportCompressedSize: true,
        sourcemap: isDev,
        rollupOptions: !isDev
          ? {
              output: {
                chunkFileNames: 'static/js/[name]-[hash].js',
                entryFileNames: 'static/js/[name]-[hash].js',
                assetFileNames: 'static/[ext]/[name]-[hash].[ext]',
                manualChunks(id) {
                  if (
                    id.includes('/react@') ||
                    id.includes('/react-dom@') ||
                    id.includes('/react-is@') ||
                    id.includes('/yjs@') ||
                    id.includes('/y-indexeddb@') ||
                    id.includes('/dexie') ||
                    id.includes('/redux') ||
                    id.includes('/react-custom-scrollbars')
                  ) {
                    return 'common';
                  }
                },
              },
            }
          : {},
      },
  resolve: {
    alias: [
      { find: 'src/', replacement: `${__dirname}/src/` },
      { find: '@/', replacement: `${__dirname}/src/` },
      {
        find: '$client-services',
        replacement: !!process.env.TAURI_PLATFORM
          ? `${__dirname}/src/application/services/tauri-services`
          : `${__dirname}/src/application/services/js-services`,
      },
      { find: '$icons', replacement: `${resourcesPath}/flowy_icons/` },
    ],
  },

  optimizeDeps: {
    include: [
      'react',
      'react-dom',
      '@mui/icons-material/Circle',
      'react-katex',
      // 'react-custom-scrollbars-2',
      // 'react-window',
      // 'react-virtualized-auto-sizer',
    ],
  },
});
