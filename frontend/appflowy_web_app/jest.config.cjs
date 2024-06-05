const { compilerOptions } = require('./tsconfig.json');
const { pathsToModuleNameMapper } = require('ts-jest');
const esModules = ['lodash-es', 'nanoid'].join('|');

/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  roots: ['<rootDir>'],
  modulePaths: [compilerOptions.baseUrl],
  moduleNameMapper: {
    ...pathsToModuleNameMapper(compilerOptions.paths),
    '^lodash-es(/(.*)|$)': 'lodash$1',
    '^nanoid(/(.*)|$)': 'nanoid$1',
  },
  'transform': {
    '^.+\\.(j|t)sx?$': 'ts-jest',
    '(.*)/node_modules/nanoid/.+\\.(j|t)sx?$': 'ts-jest',
  },
  'transformIgnorePatterns': [`/node_modules/(?!${esModules})`],
  testMatch: ['**/*.test.ts', '**/*.test.tsx'],
  coverageDirectory: '<rootDir>/coverage/jest',
  collectCoverage: true,
  coverageProvider: 'v8',
  coveragePathIgnorePatterns: [
    '/cypress/',
    '/coverage/',
    '/node_modules/',
    '/__tests__/',
    '/__mocks__/',
    '/__fixtures__/',
    '/__helpers__/',
    '/__utils__/',
    '/__constants__/',
    '/__types__/',
    '/__mocks__/',
    '/__stubs__/',
    '/__fixtures__/',
    '/application/folder-yjs/',
  ],
};