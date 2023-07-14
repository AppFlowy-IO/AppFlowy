const StyleDictionary = require('style-dictionary');
const fs = require('fs');
const path = require('path');

// Add comment header to generated files
StyleDictionary.registerFormat({
  name: 'css/variables',
  formatter: function(dictionary, config) {
    const header = `/**\n` + '* Do not edit directly\n' + `* Generated on ${new Date().toUTCString()}\n` + `* Generated from $pnpm css:variables \n` + `*/\n\n`;
    const allProperties = dictionary.allProperties;
    const properties = allProperties.map(prop => {
      const { name, value } = prop;
      return `  --${name}: ${value};`
    }).join('\n');
    // generate tailwind config
    generateTailwindConfig(allProperties);
    return header + `:root${this.selector} {\n${properties}\n}`
  }
});

// expand shadow tokens into a single string
StyleDictionary.registerTransform({
  name: 'shadow/spreadShadow',
  type: 'value',
  matcher: function (prop) {
    return prop.type === 'boxShadow';
  },
  transformer: function (prop) {
    // destructure shadow values from original token value
    const { x, y, blur, spread, color } = prop.original.value;

    return `${x}px ${y}px ${blur}px ${spread}px ${color}`;
  },
});

const transforms = ['attribute/cti', 'name/cti/kebab', 'shadow/spreadShadow'];

// Generate Light CSS variables
StyleDictionary.extend({
  source: ['./style-dictionary/tokens/base.json', './style-dictionary/tokens/light.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      buildPath: './src/styles/variables/',
      files: [
        {
          format: 'css/variables',
          destination: 'light.variables.css',
          selector: '',
          options: {
            outputReferences: true
          }
        },
      ],
      transforms,
    },
  },
}).buildAllPlatforms();

// Generate Dark CSS variables
StyleDictionary.extend({
  source: ['./style-dictionary/tokens/base.json', './style-dictionary/tokens/dark.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      buildPath: './src/styles/variables/',
      files: [
        {
          format: 'css/variables',
          destination: 'dark.variables.css',
          selector: '[data-dark-mode=true]',
        },
      ],
      transforms,
    },
  },
}).buildAllPlatforms();


function set(obj, path, value) {
  const lastKey = path.pop();
  const lastObj = path.reduce((obj, key) =>
    obj[key] = obj[key] || {},
    obj);
  lastObj[lastKey] = value;
}

function writeFile (file, data) {
  const header = `/**\n` + '* Do not edit directly\n' + `* Generated on ${new Date().toUTCString()}\n` + `* Generated from $pnpm css:variables \n` + `*/\n\n`;
  const exportString = `module.exports = ${JSON.stringify(data, null, 2)}`;
  fs.writeFileSync(path.join(__dirname, file), header + exportString);
}

function generateTailwindConfig(allProperties) {
  const tailwindColors = {};
  const tailwindBoxShadow = {};
  allProperties.forEach(prop => {
    const { path, type, name, value } = prop;
    if (path[0] === 'Base') {
      return;
    }
    if (type === 'color') {
      if (name.includes('fill')) {
        console.log(prop);
      }
      set(tailwindColors, path, `var(--${name})`);
    }
    if (type === 'boxShadow') {
      set(tailwindBoxShadow, ['md'], `var(--${name})`);
    }
  });
  writeFile('./tailwind/colors.cjs', tailwindColors);
  writeFile('./tailwind/box-shadow.cjs', tailwindBoxShadow);
}