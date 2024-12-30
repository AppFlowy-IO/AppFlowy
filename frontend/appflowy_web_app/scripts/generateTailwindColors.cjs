const fs = require('fs');
const path = require('path');

// Read CSS file
const cssFilePath = path.join(__dirname, '../src/styles/variables/light.variables.css');
const cssContent = fs.readFileSync(cssFilePath, 'utf-8');

// Extract color variables
const shadowVariables = cssContent.match(/--shadow:\s.*;/g);
const colorVariables = cssContent.match(/--[\w-]+:\s*#[0-9a-fA-F]{6}/g);

if (!colorVariables) {
  console.error('No color variables found in CSS file.');
  process.exit(1);
}

const shadows = shadowVariables.reduce((shadows, variable) => {
  const [name, value] = variable.split(':').map(str => str.trim());
  const formattedName = name.replace('--', '').replace(/-/g, '_');
  const key = 'md';

  shadows[key] = `var(${name})`;
  return shadows;
}, {});
// Generate Tailwind CSS colors configuration
// Replace -- with _ and - with _ in color variable names
const tailwindColors = colorVariables.reduce((colors, variable) => {
  const [name, value] = variable.split(':').map(str => str.trim());
  const formattedName = name.replace('--', '').replace(/-/g, '_');
  const category = formattedName.split('_')[0];
  const key = formattedName.replace(`${category}_`, '');

  if (!colors[category]) {
    colors[category] = {};
  }
  colors[category][key] = `var(${name})`;
  return colors;
}, {});

const tailwindColorsFormatted = JSON.stringify(tailwindColors, null, 2)
  .replace(/_/g, '-');
const header = `/**\n` + '* Do not edit directly\n' + `* Generated on ${new Date().toUTCString()}\n` + `* Generated from $pnpm css:variables \n` + `*/\n\n`;

// Write Tailwind CSS colors configuration to file
const tailwindColorTemplate = `
${header}
module.exports = ${tailwindColorsFormatted};
`;

const tailwindShadowTemplate = `
${header}
module.exports = ${JSON.stringify(shadows, null, 2).replace(/_/g, '-')};
`;

const tailwindConfigFilePath = path.join(__dirname, '../tailwind/colors.cjs');
fs.writeFileSync(tailwindConfigFilePath, tailwindColorTemplate, 'utf-8');

const tailwindShadowFilePath = path.join(__dirname, '../tailwind/box-shadow.cjs');
fs.writeFileSync(tailwindShadowFilePath, tailwindShadowTemplate, 'utf-8');

console.log('Tailwind CSS colors configuration generated successfully.');
