const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const jestCoverageFile = path.join(__dirname, '../coverage/jest/coverage-final.json');
const cypressCoverageFile = path.join(__dirname, '../coverage/cypress/coverage-final.json');
// const cypressComponentCoverageFile = path.join(__dirname, '../coverage/cypress-component/coverage-final.json');
const nycOutputDir = path.join(__dirname, '../coverage/.nyc_output');
// Ensure .nyc_output directory exists
if (!fs.existsSync(nycOutputDir)) {
  fs.mkdirSync(nycOutputDir, { recursive: true });
}
// Copy Jest coverage file
fs.copyFileSync(jestCoverageFile, path.join(nycOutputDir, 'jest-coverage.json'));
// Copy Cypress E2E coverage file
fs.copyFileSync(cypressCoverageFile, path.join(nycOutputDir, 'cypress-coverage.json'));
// Copy Cypress Component coverage file
// fs.copyFileSync(cypressComponentCoverageFile, path.join(nycOutputDir, 'cypress-component-coverage.json'));
// Merge coverage files
execSync('nyc merge ./coverage/.nyc_output ./coverage/merged/coverage-final.json', { stdio: 'inherit' });
// Generate final merged report
execSync('nyc report --reporter=html --reporter=text-summary --report-dir=coverage/merged --temp-dir=coverage/.nyc_output', { stdio: 'inherit' });
console.log(`Merged coverage report written to coverage/merged`);

const GITHUB_STEP_SUMMARY = process.env.GITHUB_STEP_SUMMARY;

if (GITHUB_STEP_SUMMARY) {
  const coverageSummary = execSync('nyc report --reporter=html --reporter=text-summary --report-dir=coverage/merged --temp-dir=coverage/.nyc_output').toString();

  fs.appendFileSync(GITHUB_STEP_SUMMARY, `### Coverage Report\n\`\`\`\n${coverageSummary}\n\`\`\`\n`);
}

