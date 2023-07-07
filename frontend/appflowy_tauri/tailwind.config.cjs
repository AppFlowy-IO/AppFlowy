/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
    './node_modules/react-tailwindcss-datepicker/dist/index.esm.js',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        text: {
          title: 'var(--color-text-title)',
          caption: 'var(--color-text-caption)',
          placeholder: 'var(--color-text-placeholder)',
          disabled: 'var(--color-text-disabled)',
          link: {
            default: 'var(--color-text-link-default)',
            hover: 'var(--color-text-link-hover)',
            pressed: 'var(--color-text-link-pressed)',
            disabled: 'var(--color-text-link-disabled)',
          }
        },
        content: {
          default: 'var(--color-content-default)',
          hover: 'var(--color-content-hover)',
          pressed: 'var(--color-content-pressed)',
          disabled: 'var(--color-content-disabled)',
          onfill: 'var(--color-content-onfill)',
        },
        icon: {
          default: 'var(--color-icon-default)',
          secondary: 'var(--color-icon-secondary)',
          disabled: 'var(--color-icon-disabled)',
        },
        fill: {
          default: 'var(--color-fill-default)',
          hover: 'var(--color-fill-hover)',
          selector: 'var(--color-fill-selector)',
          active: 'var(--color-fill-active)',
        },
        line: {
          divider: 'var(--color-line-divider)',
          border: 'var(--color-line-border)',
        },
        bg: {
          body: 'var(--color-bg-body)',
          base: 'var(--color-bg-base)',
          mask: 'var(--color-bg-mask)',
          brand: 'var(--color-bg-brand)',
          tips: 'var(--color-bg-tips)',
        },
        function: {
          success: 'var(--color-function-success)',
          warning: 'var(--color-function-warning)',
          error: 'var(--color-function-error)',
          info: 'var(--color-function-info)',
        },

        tint: {
          1: 'var(--color-tint-1)',
          2: 'var(--color-tint-2)',
          3: 'var(--color-tint-3)',
          4: 'var(--color-tint-4)',
          5: 'var(--color-tint-5)',
          6: 'var(--color-tint-6)',
          7: 'var(--color-tint-7)',
          8: 'var(--color-tint-8)',
          9: 'var(--color-tint-9)',
        }
      },
      boxShadow: {
        md: '0px 0px 20px rgba(0, 0, 0, 0.1);',
      },
    },
  },
  plugins: [],
};
