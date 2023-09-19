const { compilerOptions } = require('./tsconfig.json');
const { pathsToModuleNameMapper } = require("ts-jest");

/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>'],
  modulePaths: [compilerOptions.baseUrl],
  moduleNameMapper: pathsToModuleNameMapper(compilerOptions.paths),
  "transform": {
    "(.*)/node_modules/nanoid/.+\\.(j|t)sx?$": "ts-jest"
  },
  "transformIgnorePatterns": [
    "node_modules/(?!nanoid/.*)"
  ],
  "testRegex": "(/__tests__/.*\.(test|spec))\\.(jsx?|tsx?)$",
};