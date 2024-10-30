import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import svgr from 'vite-plugin-svgr';
import { visualizer } from 'rollup-plugin-visualizer';
import usePluginImport from 'vite-plugin-importer';
import { totalBundleSize } from 'vite-plugin-total-bundle-size';
import path from 'path';
import istanbul from 'vite-plugin-istanbul';
import { createHtmlPlugin } from 'vite-plugin-html';
import { viteExternalsPlugin } from 'vite-plugin-externals';

const resourcesPath = path.resolve(__dirname, '../resources');
const isDev = process.env.NODE_ENV === 'development';
const isProd = process.env.NODE_ENV === 'production';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    react(),
    createHtmlPlugin({
      inject: {
        data: {
          injectCdn: isProd,
          cdnLinks: isProd ? `
              <link rel="dns-prefetch" href="//cdn.jsdelivr.net">
              <link rel="preconnect" href="//cdn.jsdelivr.net">
              
              <script crossorigin src="https://cdn.jsdelivr.net/npm/react@18.2.0/umd/react.production.min.js"></script>
              <script crossorigin src="https://cdn.jsdelivr.net/npm/react-dom@18.2.0/umd/react-dom.production.min.js"></script>
            ` : '',
        },
      },
    }),
    isProd ? viteExternalsPlugin({
      react: 'React',
      'react-dom': 'ReactDOM',

    }) : undefined,
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
            {
              name: 'prefixIds',
              params: {
                prefix: (node, { path }) => {
                  const fileName = path?.split('/')?.pop()?.split('.')?.[0];
                  return `${fileName}-`;
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
          'black': 'currentColor',
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
      rollupOptions: isProd
        ? {
          output: {
            chunkFileNames: 'static/js/[name]-[hash].js',
            entryFileNames: 'static/js/[name]-[hash].js',
            assetFileNames: 'static/[ext]/[name]-[hash].[ext]',
            manualChunks (id) {
              if (
                // id.includes('/react@') ||
                // id.includes('/react-dom@') ||
                id.includes('/react-is@') ||
                id.includes('/yjs@') ||
                id.includes('/y-indexeddb@') ||
                id.includes('/dexie') ||
                id.includes('/redux') ||
                id.includes('/react-custom-scrollbars') ||
                id.includes('/dayjs') ||
                id.includes('/smooth-scroll-into-view-if-needed') ||
                id.includes('/react-virtualized-auto-sizer') ||
                id.includes('/react-window')
                || id.includes('/@popperjs')
                || id.includes('/@mui/material/Dialog')
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
      { find: 'cypress/support', replacement: `${__dirname}/cypress/support` },
    ],
  },

  optimizeDeps: {
    include: ['react', 'react-dom', 'react-katex'],
  },
});
