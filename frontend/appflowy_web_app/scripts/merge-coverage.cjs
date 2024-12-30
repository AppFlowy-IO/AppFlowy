const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const jestCoverageFile = path.join(__dirname, '../coverage/jest/coverage-final.json');
const cypressCoverageFile = path.join(__dirname, '../coverage/cypress/coverage-final.json');
const nycOutputDir = path.join(__dirname, '../coverage/.nyc_output');

// Ensure .nyc_output directory exists
if (fs.existsSync(nycOutputDir)) {
  fs.rmSync(nycOutputDir, { recursive: true });
}
fs.mkdirSync(nycOutputDir, { recursive: true });

if (fs.existsSync(path.join(__dirname, '../coverage/merged'))) {
  fs.rmSync(path.join(__dirname, '../coverage/merged'), { recursive: true });
}
// Copy Jest coverage file
fs.copyFileSync(jestCoverageFile, path.join(nycOutputDir, 'jest-coverage.json'));
// Copy Cypress E2E coverage file
fs.copyFileSync(cypressCoverageFile, path.join(nycOutputDir, 'cypress-coverage.json'));

// Merge coverage files
execSync('nyc merge ./coverage/.nyc_output ./coverage/merged/coverage-final.json', { stdio: 'inherit' });

// Move the merged result to the .nyc_output directory
fs.rmSync(nycOutputDir, { recursive: true });
fs.mkdirSync(nycOutputDir, { recursive: true });
fs.copyFileSync(path.join(__dirname, '../coverage/merged/coverage-final.json'), path.join(nycOutputDir, 'out.json'));

// Generate final merged report
execSync('nyc report --reporter=html --reporter=text-summary --report-dir=coverage/merged --temp-dir=coverage/.nyc_output', { stdio: 'inherit' });
console.log(`Merged coverage report written to coverage/merged`);



