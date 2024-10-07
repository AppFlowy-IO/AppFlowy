import { initialEditorTest, moveCursor } from '@/components/editor/__tests__/mount';
import { FromBlockJSON } from 'cypress/support/document';

const initialData: FromBlockJSON[] = [
  {
    type: 'paragraph',
    data: {},
    text: [{ insert: 'Outer paragraph' }],
    children: [],
  },
  {
    type: 'toggle_list',
    data: {},
    text: [{ insert: 'Toggle list' }],
    children: [
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Nested paragraph 1' }],
        children: [{
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Deeply nested paragraph' }],
          children: [],
        }],
      },
      {
        type: 'toggle_list',
        data: {},
        text: [{ insert: 'Nested toggle list' }],
        children: [
          {
            type: 'paragraph',
            data: {},
            text: [{ insert: 'Deeply nested paragraph' }],
            children: [],
          },
        ],
      },
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Nested paragraph 2.' }],
        children: [],
      },
    ],
  },
  {
    type: 'paragraph',
    data: {},
    text: [{ insert: 'Final outer paragraph' }],
    children: [],
  },
];
const { assertJSON, initializeEditor } = initialEditorTest();

describe('Tab key behavior', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');
  });

  it('should indent paragraph when tab at start of paragraph', () => {
    moveCursor(1, 0);  // Move to 'Toggle list'
    cy.get('@editor').realPress('Tab');
    assertJSON([
      {
        ...initialData[0],
        children: [initialData[1]],
      },
      initialData[2],
    ]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/TabKeyBehavior/should-indent-paragraph');
  });

  it('should indent nested block at index 0/1 when tab at start', () => {
    // Test 1: move to children[0]
    moveCursor(2, 0);  // Move to 'Nested paragraph 1'
    cy.get('@editor').realPress('Tab');
    assertJSON(initialData);

    // Test 2: move to children[1]
    moveCursor(4, 0);  // Move to 'Deeply nested paragraph'
    cy.get('@editor').realPress('Tab');
    assertJSON([
      initialData[0],
      {
        ...initialData[1],
        children: [
          {
            ...initialData[1].children[0],
            children: [initialData[1].children[0].children[0], initialData[1].children[1]],
          },
          initialData[1].children[2],
        ],
      },
      initialData[2],
    ]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/TabKeyBehavior/should-indent-nested-block-at-index-0-1');
  });

  it('should not indent at start of document', () => {
    moveCursor(0, 0);
    cy.get('@editor').realPress('Tab');
    assertJSON(initialData);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/TabKeyBehavior/should-not-indent-at-start-of-document');
  });

  it('should not indent at start of nested block', () => {
    moveCursor(2, 0);
    cy.get('@editor').realPress('Tab');
    assertJSON(initialData);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/TabKeyBehavior/should-not-indent-at-start-of-nested-block');
  });
});

describe('Shift+Tab key behavior', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');
  });

  it('should outdent deeply nested paragraph when shift+tab at start', () => {
    moveCursor(3, 3);  // Move to 'Deeply nested paragraph'
    cy.get('@editor').realPress(['Shift', 'Tab']);
    assertJSON([
      initialData[0],
      {
        ...initialData[1],
        children: [
          {
            ...initialData[1].children[0],
            children: [],
          },
          initialData[1].children[0].children[0],
          initialData[1].children[1],
          initialData[1].children[2],
        ],
      },
      initialData[2],
    ]);
    //
    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/ShiftTabKeyBehavior/should-outdent-deeply-nested-paragraph');
  });

  it('should outdent Nested toggle list when shift+tab at start', () => {
    moveCursor(4, 1);  // Move to 'Nested toggle list'
    cy.get('@editor').realPress(['Shift', 'Tab']);
    assertJSON([
      initialData[0],
      {
        ...initialData[1],
        children: [
          initialData[1].children[0],
          initialData[1].children[2],
        ],
      },
      initialData[1].children[1],
      initialData[2],
    ]);
    //
    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/ShiftTabKeyBehavior/should-outdent-nested-toggle-list');
  });

  it('should not outdent at top level', () => {
    moveCursor(0, 0);  // Move to 'Outer paragraph'
    cy.get('@editor').realPress(['Shift', 'Tab']);
    assertJSON(initialData);

    moveCursor(7, 0);  // Move to 'Final outer paragraph'
    cy.get('@editor').realPress(['Shift', 'Tab']);
    assertJSON(initialData);
    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/ShiftTabKeyBehavior/should-not-outdent-at-top-level');
  });

});