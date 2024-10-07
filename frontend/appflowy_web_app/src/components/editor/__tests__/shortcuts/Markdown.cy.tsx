import { mountEditor, moveCursor } from '@/components/editor/__tests__/mount';
import { DocumentTest, FromBlockJSON } from 'cypress/support/document';

let documentTest: DocumentTest;
const initialData: FromBlockJSON[] = [{
  type: 'paragraph',
  data: {},
  text: [{ insert: 'First paragraph' }],
  children: [],
}];

const initializeEditor = (data: FromBlockJSON[]) => {
  documentTest = new DocumentTest();
  documentTest.fromJSON(data);
  mountEditor({ readOnly: false, doc: documentTest.doc });
  cy.get('[role="textbox"]').should('exist');
};

const assertJSON = (expectedJSON: FromBlockJSON[]) => {
  cy.wrap(null).then(() => {
    const finalJSON = documentTest.toJSON();

    expect(finalJSON).to.deep.equal(expectedJSON);
  });
};

describe('Markdown editing', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');
  });

  it('should handle all markdown inputs', () => {
    moveCursor(0, 6);
    let expectedJson: FromBlockJSON[] = initialData;

    // Test `Bold`
    cy.get('@editor').type('**bold');
    cy.get('@editor').realPress(['*', '*']);
    expectedJson = [{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First ' }, { insert: 'bold', attributes: { bold: true } }, { insert: 'paragraph' }],
      children: [],
    }];
    assertJSON(expectedJson);
    cy.get('@editor').type('{moveToEnd}');

    cy.get('@editor').realPress('Enter');
    // Test 1: heading
    cy.get('@editor').type('##');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('Heading 2');
    expectedJson = [...expectedJson, {
      type: 'heading',
      data: { level: 2 },
      text: [{ insert: 'Heading 2' }],
      children: [],
    }];

    assertJSON(expectedJson);
    // Test `Italic`
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('_italic');
    cy.get('@editor').realPress(['_']);
    expectedJson = [
      ...expectedJson,
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'italic', attributes: { italic: true } }],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    cy.get('@editor').type('__bold italic');
    cy.get('@editor').realPress(['_', '_']);
    expectedJson = [
      ...expectedJson.slice(0, -1),
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'italic', attributes: { italic: true } }, {
          insert: 'bold italic',
          attributes: { bold: true, italic: true },
        }],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    // Test `Code`
    cy.get('@editor').type(' `code');
    cy.get('@editor').realPress(['`']);
    expectedJson = [
      ...expectedJson.slice(0, -1),
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'italic', attributes: { italic: true } }, {
          insert: 'bold italic ',
          attributes: { bold: true, italic: true },
        },
          {
            insert: 'code',
            attributes: { code: true, italic: true, bold: true },
          }],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    // Test `Inline formula`
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('$E=mc^2');
    cy.get('@editor').realPress(['$']);
    expectedJson = [
      ...expectedJson,
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: '$', attributes: { formula: 'E=mc^2' } }],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    // Test `Strikethrough`
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('~~strikethrough');
    cy.get('@editor').realPress(['~', '~']);
    expectedJson = [
      ...expectedJson,
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'strikethrough', attributes: { strikethrough: true } }],
        children: [],
      },
    ];
    assertJSON(expectedJson);

    // Test 2: quote
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('"');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('quote list');

    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('quote child');

    expectedJson = [
      ...expectedJson,
      {
        type: 'quote',
        data: {},
        text: [{ insert: 'quote list' }],
        children: [{
          type: 'paragraph',
          data: {},
          children: [],
          text: [{ insert: 'quote child' }],
        }],
      },
    ];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress(['Shift', 'Tab']);

    // Test 3: Todo list
    cy.get('@editor').type('-[]');
    cy.get('@editor').realPress('Space');

    expectedJson = [
      ...expectedJson,
      {
        type: 'todo_list',
        data: { checked: false },
        text: [],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Backspace');
    cy.get('@editor').type('-[x]');
    cy.get('@editor').realPress('Space');
    expectedJson = [
      ...expectedJson.slice(0, -1),
      {
        type: 'todo_list',
        data: { checked: true },
        text: [],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Backspace');
    cy.get('@editor').type('-[ ]');
    cy.get('@editor').realPress('Space');
    expectedJson = [
      ...expectedJson.slice(0, -1),
      {
        type: 'todo_list',
        data: { checked: false },
        text: [],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    cy.get('@editor').type('todo list unchecked');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('-[x]');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('todo list checked');
    expectedJson = [
      ...expectedJson.slice(0, -1),
      {
        type: 'todo_list',
        data: { checked: false },
        text: [{ insert: 'todo list unchecked' }],
        children: [],
      },
      {
        type: 'todo_list',
        data: { checked: true },
        text: [{ insert: 'todo list checked' }],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress('Backspace');

    // Test 4: Toggle list
    cy.get('@editor').type('>');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('toggle list');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('toggle list child');
    expectedJson = [
      ...expectedJson,
      {
        type: 'toggle_list',
        data: { collapsed: false },
        text: [{ insert: 'toggle list' }],
        children: [{
          type: 'paragraph',
          data: {},
          children: [],
          text: [{ insert: 'toggle list child' }],
        }],
      },
    ];
    assertJSON(expectedJson);

    // Test 5: Bullted List
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress('Backspace');
    cy.get('@editor').type('-');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('bulleted list');
    expectedJson = [
      ...expectedJson,
      {
        type: 'bulleted_list',
        data: {},
        text: [{ insert: 'bulleted list' }],
        children: [],
      },

    ];
    assertJSON(expectedJson);
    // Test 5: Numbered List
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('2.');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('numbered list');
    expectedJson = [
      ...expectedJson,
      {
        type: 'numbered_list',
        data: { number: 2 },
        text: [{ insert: 'numbered list' }],
        children: [],
      },
    ];
    assertJSON(expectedJson);

    // Test 6: Code block
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress('Backspace');
    cy.get('@editor').type('```');
    cy.get('@editor').type(`function main() {\n  console.log('Hello, World!');\n}`);
    cy.get('@editor').realPress(['Shift', 'Enter']);
    expectedJson = [
      ...expectedJson,
      {
        type: 'code',
        data: {},
        text: [{
          insert: 'function main() {\n  console.log(\'Hello, World!\');\n}',
        }],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    // Last test: Divider
    cy.get('@editor').type('--');
    cy.get('@editor').realPress('-');
    expectedJson = [
      ...expectedJson.slice(0, -1),
      {
        type: 'divider',
        data: {},
        text: [],
        children: [],
      },
    ];
    assertJSON(expectedJson);
  });
});