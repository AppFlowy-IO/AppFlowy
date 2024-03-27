import resources from './resources';

declare module 'i18next' {
  interface CustomTypeOptions {
    defaultNS: 'translation';
    resources: typeof resources;
  }
}
