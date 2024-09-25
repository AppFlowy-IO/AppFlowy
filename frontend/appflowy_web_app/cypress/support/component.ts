// ***********************************************************
// This example support/component.ts is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************
import { addMatchImageSnapshotCommand } from 'cypress-image-snapshot/command';

// Import commands.js using ES2015 syntax:
import '@cypress/code-coverage/support';
import './commands';
import './document';

// Alternatively you can use CommonJS syntax:
// require('./commands')

import { mount } from 'cypress/react18';

// Augment the Cypress namespace to include type definitions for
// your custom command.
// Alternatively, can be defined in cypress/support/component.d.ts
// with a <reference path="./component" /> at the top of your spec.
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Cypress {
    interface Chainable {
      mount: typeof mount;
      mockAPI: () => void;
      mockDatabase: () => void;
      mockCurrentWorkspace: () => void;
      mockGetWorkspaceDatabases: () => void;
      mockDocument: (id: string) => void;
      clickOutside: () => void;
      getTestingSelector: (testId: string) => Chainable<JQuery<HTMLElement>>;
    }
  }
}

Cypress.Commands.add('mount', mount);

Cypress.Commands.add('getTestingSelector', (testId: string) => {
  return cy.get(`[data-testid="${testId}"]`);
});

Cypress.Commands.add('clickOutside', () => {
  cy.document().then((doc) => {
    // [0, 0] is the top left corner of the window
    const x = 0;
    const y = 0;

    const evt = new MouseEvent('click', {
      bubbles: true,
      cancelable: true,
      view: window,
      clientX: x,
      clientY: y,
    });

    // Dispatch the event
    doc.elementFromPoint(x, y)?.dispatchEvent(evt);
  });
});
// Example use:
// cy.mount(<MyComponent />)

addMatchImageSnapshotCommand({
  failureThreshold: 0.03, // 允许 3% 的像素差异
  failureThresholdType: 'percent',
  customDiffConfig: { threshold: 0.1 },
  capture: 'viewport',
});
