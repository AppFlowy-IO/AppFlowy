import { initialEditorTest, moveCursor } from '@/components/editor/__tests__/mount';
import { FromBlockJSON } from 'cypress/support/document';

const initialData: FromBlockJSON[] = [{
  type: 'paragraph',
  data: {},
  text: [{ insert: 'First paragraph' }],
  children: [],
}];

const { assertJSON, initializeEditor } = initialEditorTest();

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
    cy.wait(50);

    cy.get('@editor').type('Heading 2');
    expectedJson = [...expectedJson, {
      type: 'heading',
      data: { level: 2 },
      text: [{ insert: 'Heading 2' }],
      children: [],
    }];

    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('#');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('Heading 1');
    expectedJson = [...expectedJson, {
      type: 'heading',
      data: { level: 1 },
      text: [{ insert: 'Heading 1' }],
      children: [],
    }];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('###');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('Heading 3');
    expectedJson = [...expectedJson, {
      type: 'heading',
      data: { level: 3 },
      text: [{ insert: 'Heading 3' }],
      children: [],
    }];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('####');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('Heading 4');
    expectedJson = [...expectedJson, {
      type: 'heading',
      data: { level: 4 },
      text: [{ insert: 'Heading 4' }],
      children: [],
    }];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress('Tab');
    cy.get('@editor').type('paragraph: heading can not be nested');
    expectedJson = [...expectedJson, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'paragraph: heading can not be nested' }],
      children: [],
    }];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress('Tab');
    cy.get('@editor').type('#####');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('Heading 5');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('######');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('Heading 6');
    expectedJson = [...expectedJson.slice(0, -1), {
      ...expectedJson[expectedJson.length - 1],
      children: [{
        type: 'heading',
        data: { level: 5 },
        text: [{ insert: 'Heading 5' }],
        children: [],
      }, {
        type: 'heading',
        data: { level: 6 },
        text: [{ insert: 'Heading 6' }],
        children: [],
      }],
    }];
    assertJSON(expectedJson);

    cy.get('@editor').realPress(['Enter', 'Enter']);
    cy.get('@editor').type('Outer paragraph');

    moveCursor(5, 0);
    cy.get('@editor').type('#');
    cy.get('@editor').realPress('Space');
    expectedJson = [...expectedJson.slice(0, 5), {
      ...expectedJson[5],
      type: 'heading',
      data: { level: 1 },
      children: [],
    }, {
      type: 'heading',
      data: { level: 5 },
      text: [{ insert: 'Heading 5' }],
      children: [],
    }, {
      type: 'heading',
      data: { level: 6 },
      text: [{ insert: 'Heading 6' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Outer paragraph' }],
      children: [],
    }];
    assertJSON(expectedJson);
    cy.wait(500);
    cy.get('@editor').type('{movetoend}');

    cy.get('@editor').realPress(['Enter', 'Tab']);
    cy.get('@editor').type('Inner paragraph');
    cy.get('@editor').realPress(['Enter']);
    cy.get('@editor').type('Hi');
    cy.get('@editor').realPress(['ArrowLeft', 'ArrowLeft']);
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress('ArrowUp');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('Hello');
    expectedJson = [...expectedJson.slice(0, -1), {
      ...expectedJson[expectedJson.length - 1],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Inner paragraph' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hello' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hi' }],
        children: [],
      }],
    }];
    assertJSON(expectedJson);
    moveCursor(12, 2);
    cy.get('@editor').realPress(['Enter', 'Backspace']);

    // Test `Italic`
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

    cy.get('@editor').type('inline formula');
    expectedJson = [
      ...expectedJson,
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: '$', attributes: { formula: 'E=mc^2' } }, { insert: 'inline formula' }],
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

    // Test 7: Toggle heading
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('>');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('toggle heading');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('toggle heading child');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress(['Shift', 'Tab']);
    cy.get('@editor').type('toggle heading sibling');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').type('###');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('heading 3');
    cy.get('@editor').selectMultipleText(['toggle heading']);
    cy.wait(500);
    cy.get('@editor').realPress(['ArrowLeft']);
    cy.get('@editor').type('#');
    cy.get('@editor').realPress('Space');
    const extraData: FromBlockJSON[] = [{
      type: 'toggle_list',
      data: {
        level: 1,
        collapsed: false,
      },
      text: [{
        insert: 'toggle heading',
      }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{
          insert: 'toggle heading child',
        }],
        children: [],
      }],
    },
      {
        type: 'paragraph',
        data: {},
        text: [{
          insert: 'toggle heading sibling',
        }],
        children: [],
      },
      {
        type: 'heading',
        data: {
          level: 3,
        },
        text: [{
          insert: 'heading 3',
        }],
        children: [],

      }];

    assertJSON([
      ...expectedJson,
      ...extraData,
    ]);
    cy.get('@editor').realPress('Backspace');
    assertJSON([
      ...expectedJson,
      {
        ...extraData[0],
        data: {
          collapsed: false,
          level: null,
        },
      },
      extraData[1],
      extraData[2],
    ] as FromBlockJSON[]);
    cy.get('@editor').realPress('Backspace');
    assertJSON([
      ...expectedJson,
      {
        ...extraData[0],
        type: 'paragraph',
        data: {},
      },
      extraData[1],
      extraData[2],
    ] as FromBlockJSON[]);
    cy.get('@editor').type('#');
    cy.get('@editor').realPress('Space');
    cy.get('@editor').type('>');
    cy.get('@editor').realPress('Space');
    expectedJson = [
      ...expectedJson,
      {
        ...extraData[0],
        children: [
          extraData[0].children[0],
          extraData[1],
          extraData[2],
        ],
      },
    ] as FromBlockJSON[];

    assertJSON(expectedJson);

    cy.selectMultipleText(['heading 3']);
    cy.wait(500);
    cy.get('@editor').realPress('ArrowRight');
    cy.get('@editor').realPress('Enter');
    cy.get('@editor').realPress(['Shift', 'Tab']);

    // Test 8: Link
    cy.get('@editor').type('Link: [Click here](https://example.com');
    cy.get('@editor').realPress(')');
    assertJSON([
      ...expectedJson,
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Link: ' }, {
          insert: 'Click here',
          attributes: { href: 'https://example.com' },
        }],
        children: [],
      },
    ]);
    cy.get('@editor').type('link anchor');
    expectedJson = [
      ...expectedJson,
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Link: ' }, {
          insert: 'Click here',
          attributes: { href: 'https://example.com' },
        }, { insert: 'link anchor' }],
        children: [],
      },
    ];
    assertJSON(expectedJson);
    cy.get('@editor').realPress('Enter');
    //
    // Last test: Divider
    cy.get('@editor').type('--');
    cy.get('@editor').realPress('-');
    expectedJson = [
      ...expectedJson,
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