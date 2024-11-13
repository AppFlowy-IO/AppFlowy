import { initialEditorTest, moveCursor } from '@/components/editor/__tests__/mount';
import { FromBlockJSON } from 'cypress/support/document';

const initialData: FromBlockJSON[] = [{
  type: 'paragraph',
  data: {},
  text: [{ insert: '' }],
  children: [],
}];

const { assertJSON, initializeEditor } = initialEditorTest();

describe('Divider', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');

    cy.wait(1000);

    cy.get(selector).focus();
  });

  it('should turn to divider when typing ---', () => {
    moveCursor(0, 0);
    cy.get('@editor').type('--');
    cy.get('@editor').realPress('-');
    assertJSON([
      {
        type: 'divider',
        data: {},
        text: [],
        children: [],
      },
    ]);
  });

  it('should add a paragraph below the divider when pressing Enter', () => {
    moveCursor(0, 0);
    cy.get('@editor').type('--');
    cy.get('@editor').realPress('-');
    cy.get('@editor').get('[data-block-type="divider"]').as('divider');
    cy.get('@divider').should('exist');
    cy.get('@editor').realPress('Enter');
    assertJSON([
      {
        type: 'divider',
        data: {},
        text: [],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      },
    ]);

  });

  it('should remove the divider when pressing Backspace', () => {
    moveCursor(0, 0);
    cy.get('@editor').type('--');
    cy.get('@editor').realPress('-');
    cy.get('@editor').get('[data-block-type="divider"]').as('divider');
    cy.get('@divider').should('exist');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress(['ArrowUp', 'Backspace']);
    cy.get('@editor').get('[data-block-type="divider"]').should('not.exist');
    assertJSON([
      {
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      },
    ]);
  });
});