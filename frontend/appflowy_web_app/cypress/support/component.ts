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
import 'cypress-real-events';

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
      selectText: (text: string) => void;

      selectMultipleText: (texts: string[]) => void;
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

function mergeRanges (ranges: Range[]): Range | null {
  if (ranges.length === 0) return null;

  const mergedRange = ranges[0].cloneRange();

  for (let i = 1; i < ranges.length; i++) {
    if (ranges[i].compareBoundaryPoints(Range.START_TO_START, mergedRange) < 0) {
      mergedRange.setStart(ranges[i].startContainer, ranges[i].startOffset);
    }

    if (ranges[i].compareBoundaryPoints(Range.END_TO_END, mergedRange) > 0) {
      mergedRange.setEnd(ranges[i].endContainer, ranges[i].endOffset);
    }
  }

  return mergedRange;
}

Cypress.Commands.add('selectMultipleText', (texts: string[]) => {
  const ranges: Range[] = [];

  cy.window().then((win) => {
    const promises = texts.map((text) => {
      return new Cypress.Promise((resolve) => {
        cy.contains(text).then(($el) => {
          if (!$el) {
            throw new Error(`The text "${text}" was not found in the document`);
          }

          const el = $el[0] as HTMLElement;
          const document = el.ownerDocument;
          const range = document.createRange();

          const fullText = el.textContent || '';
          const startIndex = fullText.indexOf(text);
          const endIndex = startIndex + text.length;

          if (startIndex !== -1 && endIndex !== -1) {
            range.setStart(el.firstChild as Node, startIndex);
            range.setEnd(el.firstChild as Node, endIndex);
            ranges.push(range);
          } else {
            throw new Error(`The text "${text}" was not found in the element`);
          }

          resolve();
        });
      });
    });

    void Cypress.Promise.all(promises).then(() => {
      const selection = win.getSelection();

      if (selection) {
        const mergedRange = mergeRanges(ranges);

        selection.removeAllRanges();
        if (mergedRange) {
          selection.addRange(mergedRange);

        }
      }

      cy.document().trigger('mouseup');
      cy.document().trigger('selectionchange');
    });
  });
});
Cypress.Commands.add('selectText', (text: string) => {
  cy.contains(text).then(($el) => {
    if (!$el) {
      throw new Error(`The text "${text}" was not found in the document`);
    }

    const el = $el[0] as HTMLElement;
    const document = el.ownerDocument;

    const range = document.createRange();

    range.selectNodeContents(el);

    const fullText = el.textContent || '';
    const startIndex = fullText.indexOf(text);
    const endIndex = startIndex + text.length;

    if (startIndex !== -1 && endIndex !== -1) {
      range.setStart(el.firstChild as HTMLElement, startIndex);
      range.setEnd(el.firstChild as HTMLElement, endIndex);

      const selection = document.getSelection() as Selection;

      selection.removeAllRanges();
      selection.addRange(range);

      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-expect-error
      $el.trigger('mouseup');
      cy.document().trigger('selectionchange');
    } else {
      throw new Error(`The text "${text}" was not found in the element`);
    }
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
