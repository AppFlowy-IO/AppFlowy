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
        white: '#ffffff',
        black: '#000000',
        main: {
          accent: '#00BCF0',
          hovered: '#00B7EA',
          secondary: '#E0F8FF',
          selector: '#F2FCFF',
          alert: '#FB006D',
          warning: '#FFD667',
          success: '#66CF80',
        },
        tint: {
          1: '#E8E0FF',
          2: '#FFE7FD',
          3: '#FFE7EE',
          4: '#FFEFE3',
          5: '#FFF2CD',
          6: '#F5FFDC',
          7: '#DDFFD6',
          8: '#DEFFF1',
          9: '#E1FBFF',
        },
        shade: {
          1: '#333333',
          2: '#4F4F4F',
          3: '#828282',
          4: '#BDBDBD',
          5: '#E0E0E0',
          6: '#F2F2F2',
          7: '#FFFFFF',
        },
        surface: {
          1: '#F7F8FC',
          2: '#EDEEF2',
          3: '#E2E4EB',
          fiol: '#2C144B',
        },
        custom: {
          code: 'rgba(221, 221, 221, 0.4)',
          caret: 'rgb(55, 53, 47)'
        }
      },
      boxShadow: {
        md: '0px 0px 20px rgba(0, 0, 0, 0.1);',
      },
    },
  },
  plugins: [],
};
