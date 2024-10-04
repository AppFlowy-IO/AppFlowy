import { mountEditor, moveToLineStart } from '@/components/editor/__tests__/mount';
import { DocumentTest, FromBlockJSON } from 'cypress/support/document';

describe('Backspace key behavior', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
  });
  let documentTest: DocumentTest;
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

  describe('backspace key behavior with range selections', () => {

    beforeEach(() => {
      initializeEditor(initialData);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');
    });
    it('should delete entire nested structure', () => {
      cy.selectMultipleText(['Outer paragraph', 'Final outer paragraph']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{backspace}');

      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [],
          children: [],
        },
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-delete-entire-nested-structure');
    });

    it('should delete content across multiple blocks', () => {
      cy.selectMultipleText(['Outer paragraph', 'Toggle list']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{backspace}');
      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [],
          children: initialData[1].children,
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Final outer paragraph' }],
          children: [],
        },
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-delete-content-across-multiple-blocks');
    });

    it('should delete nested content within a toggle list', () => {
      cy.selectMultipleText(['Nested paragraph 1', 'Nested paragraph 2']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{backspace}');
      assertJSON([
        initialData[0],
        {
          type: 'toggle_list',
          data: {},
          text: [{ insert: 'Toggle list' }],
          children: [
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: '.' }],
              children: [],
            },

          ],
        },
        initialData[2],
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-delete-nested-content-within-a-toggle-list');
    });

    it('should delete content across different nesting levels', () => {
      cy.selectMultipleText(['Toggle list', 'Deeply nested']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{backspace}');
      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Outer paragraph' }],
          children: [],
        },
        {
          type: 'toggle_list',
          data: {},
          text: [{ insert: ' paragraph' }],
          children: initialData[1].children.slice(1),
        },
        initialData[2],
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-delete-content-across-different-nesting-levels');
    });

    it('should handle deletion of deeply nested content', () => {
      cy.selectMultipleText(['ested paragraph 1', 'Deeply nested paragraph']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{backspace}');
      assertJSON([
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
          children: [{
            type: 'paragraph',
            data: {},
            text: [{ insert: 'N' }],
            children: [],
          }, ...initialData[1].children.slice(1)],
        },
        initialData[2],
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-handle-deletion-of-deeply-nested-content');
    });

    it('should maintain structure when deleting partial content', () => {
      cy.selectMultipleText(['paragraph', 'Toggle']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{backspace}');
      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Outer  list' }],
          children: initialData[1].children,
        },

        initialData[2],
      ]);
      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-maintain-structure-when-deleting-partial-content');
    });
  });

  describe('backspace key behavior with cursor selections', () => {
    beforeEach(() => {
      initializeEditor(initialData);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');
    });

    it('should convert non-paragraph block to paragraph on backspace at start', () => {
      moveToLineStart(1);  // Move to start of toggle list
      cy.get('@editor').type('{backspace}');
      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Outer paragraph' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Toggle list' }],
          children: initialData[1].children,
        },
        initialData[2],
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-convert-non-paragraph-block-to-paragraph');
    });

    it('should merge paragraphs when backspace at start of paragraph', () => {
      moveToLineStart(2);  // Move to start of "Nested paragraph 1"
      cy.get('@editor').type('{backspace}');
      assertJSON([
        initialData[0],
        {
          type: 'toggle_list',
          data: {},
          text: [{ insert: 'Toggle listNested paragraph 1' }],
          children: [
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: 'Deeply nested paragraph' }],
              children: [],
            }, ...initialData[1].children.slice(1),
          ],
        },
        initialData[2],
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-merge-paragraphs');
    });

    it('should lift nested paragraph when backspace at start', () => {
      moveToLineStart(3);  // Move to "Deeply nested paragraph"
      cy.get('@editor').type('{backspace}');
      assertJSON([
        initialData[0],
        {
          type: 'toggle_list',
          data: {},
          text: [{ insert: 'Toggle list' }],
          children: [
            {
              ...initialData[1].children[0],
              children: [],
            }, {
              type: 'paragraph',
              data: {},
              text: [{ insert: 'Deeply nested paragraph' }],
              children: [],
            },
            ...initialData[1].children.slice(1),
          ],
        },
        initialData[2],
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-lift-nested-paragraph');
    });

    it('should merge nested toggle list when backspace at start', () => {
      moveToLineStart(4);  // Move to "Nested toggle list"
      cy.get('@editor').type('{backspace}');
      assertJSON([
        initialData[0],
        {
          type: 'toggle_list',
          data: {},
          text: [{ insert: 'Toggle list' }],
          children: [
            initialData[1].children[0],
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: 'Nested toggle list' }],
              children: initialData[1].children[1].children,
            },
            initialData[1].children[2],
          ],
        },
        initialData[2],
      ]);

      // Optional: Add visual regression test

      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-merge-nested-toggle-list');
    });

    it('should handle backspace at start of document', () => {
      moveToLineStart(0);
      cy.get('@editor').type('{backspace}');
      assertJSON(initialData);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/BackspaceKeyBehavior/should-handle-backspace-at-start-of-document');
    });
  });
});