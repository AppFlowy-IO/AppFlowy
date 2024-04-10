const colors = require('./style-dictionary/tailwind/colors.cjs');
const boxShadow = require('./style-dictionary/tailwind/box-shadow.cjs');

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
    './node_modules/react-tailwindcss-datepicker/dist/index.esm.js',
  ],
  important: '#body',
  darkMode: 'class',
  theme: {
    extend: {
      colors,
      boxShadow,
    },
  },
  plugins: [],
};
