const { compilerOptions } = require('./tsconfig.json');
const { pathsToModuleNameMapper } = require('ts-jest');
const esModules = ['lodash-es', 'nanoid'].join('|');

/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>'],
  modulePaths: [compilerOptions.baseUrl],
  moduleNameMapper: {
    ...pathsToModuleNameMapper(compilerOptions.paths),
    '^lodash-es(/(.*)|$)': 'lodash$1',
    '^nanoid(/(.*)|$)': 'nanoid$1',
  },
  'transform': {
    '(.*)/node_modules/nanoid/.+\\.(j|t)sx?$': 'ts-jest',
  },
  'transformIgnorePatterns': [`/node_modules/(?!${esModules})`],
  testMatch: ['**/*.test.ts'],
};