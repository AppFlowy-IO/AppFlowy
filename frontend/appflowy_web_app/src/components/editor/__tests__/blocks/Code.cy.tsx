import { initialEditorTest, moveCursor } from '@/components/editor/__tests__/mount';
import { FromBlockJSON } from 'cypress/support/document';

const initialData: FromBlockJSON[] = [{
  type: 'paragraph',
  data: {},
  text: [{ insert: '' }],
  children: [],
}];

const { assertJSON, initializeEditor } = initialEditorTest();

describe('CodeBlock', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');

    cy.wait(1000);

    cy.get(selector).focus();
  });

  it('should turn to code block when typing ```', () => {
    moveCursor(0, 0);
    cy.get('@editor').type('```');
    cy.get('@editor').type(`function main() {\n  console.log('Hello, World!');\n}`);
    assertJSON([
      {
        type: 'code',
        data: {},
        text: [{ insert: 'function main() {\n  console.log(\'Hello, World!\');\n}' }],
        children: [],
      },
    ]);
  });

  it('should add a paragraph below the code block when pressing Shift+Enter', () => {
    moveCursor(0, 0);
    cy.get('@editor').type('```');
    cy.get('@editor').type(`function main() {\n  console.log('Hello, World!');\n}`);
    cy.get('@editor').get('[data-block-type="code"]').as('code');
    cy.get('@code').should('exist');
    cy.get('@editor').realPress(['Shift', 'Enter']);
    assertJSON([
      {
        type: 'code',
        data: {},
        text: [{ insert: 'function main() {\n  console.log(\'Hello, World!\');\n}' }],
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

  it('should insert soft break when pressing Enter', () => {
    moveCursor(0, 0);
    cy.get('@editor').type('```');
    cy.get('@editor').type(`function main() {\n  console.log('Hello, World!');\n}`);

    cy.get('@editor').realPress('Enter');
    assertJSON([
      {
        type: 'code',
        data: {},
        text: [{ insert: 'function main() {\n  console.log(\'Hello, World!\');\n}\n' }],
        children: [],
      },
    ]);
  });

  it('should remove the code block when pressing Backspace at the beginning', () => {
    moveCursor(0, 0);
    cy.get('@editor').type('```');
    cy.get('@editor').type(`function main() {\n  console.log('Hello, World!');\n}`);

    cy.get('@editor').get('[data-block-type="code"]').as('code');
    cy.get('@code').should('exist');
    moveCursor(0, 0);
    cy.get('@editor').realPress(['Backspace']);
    cy.get('@editor').get('[data-block-type="code"]').should('not.exist');
    assertJSON([
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'function main() {\n  console.log(\'Hello, World!\');\n}' }],
        children: [],
      },
    ]);
  });

});