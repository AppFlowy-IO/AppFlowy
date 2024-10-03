import { mountEditor } from '@/components/editor/__tests__/mount';
import { DocumentTest, FromBlockJSON } from 'cypress/support/document';

describe('Enter key behavior', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
  });
  let documentTest: DocumentTest;

  const initializeEditor = (data: FromBlockJSON[]) => {
    documentTest = new DocumentTest();
    documentTest.fromJSON(data);
    mountEditor({ readOnly: false, doc: documentTest.doc });
    cy.get('[role="textbox"]').should('exist');
  };

  const moveToLineStart = (lineIndex: number) => {
    const selector = '[role="textbox"]';

    cy.get(selector).as('targetBlock');

    if (lineIndex === 0) {
      cy.get('@targetBlock').type('{movetostart}').wait(50);
    } else {
      cy.get('@targetBlock').type('{movetostart}').type('{downarrow}'.repeat(lineIndex))
        .wait(50);
    }
  };

  const moveAndEnter = (lineIndex: number, moveCount: number) => {
    moveToLineStart(lineIndex);
    // Move the cursor with right arrow key and batch the movement
    const batchSize = 5;
    const batches = Math.ceil(moveCount / batchSize);

    for (let i = 0; i < batches; i++) {
      const remainingMoves = Math.min(batchSize, moveCount - i * batchSize);

      cy.get('@targetBlock')
        .type('{rightarrow}'.repeat(remainingMoves))
        .wait(50);
    }

    cy.get('@targetBlock').type('{enter}');
  };

  const assertJSON = (expectedJSON: FromBlockJSON[]) => {
    cy.wrap(null).then(() => {
      const finalJSON = documentTest.toJSON();

      expect(finalJSON).to.deep.equal(expectedJSON);
    });
  };

  it('should split paragraph blocks correctly', () => {
    const initialData: FromBlockJSON[] = [{
      type: 'paragraph',
      data: {},
      text: [
        { insert: 'First line ' },
        { insert: 'bold format ', attributes: { bold: true } },
        { insert: 'line end.' },
      ],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Second line' }],
      children: [],
    }];

    initializeEditor(initialData);

    // Test 1: Split in the middle of a formatted text
    moveAndEnter(0, 16);
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First line ' }, { insert: 'bold ', attributes: { bold: true } }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'format ', attributes: { bold: true } }, { insert: 'line end.' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Second line' }],
      children: [],
    }]);

    // Test 2: Split at the end of a paragraph
    moveAndEnter(2, 7);
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First line ' }, { insert: 'bold ', attributes: { bold: true } }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'format ', attributes: { bold: true } }, { insert: 'line end.' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Second ' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'line' }],
      children: [],
    }]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/enter-key-behavior-split-paragraph-block');
  });

  it('should handle enter key correctly with nested paragraphs', () => {
    const initialData: FromBlockJSON[] = [{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Parent paragraph' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child paragraph 1' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child paragraph 2' }],
        children: [],
      }],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Sibling paragraph' }],
      children: [],
    }];

    initializeEditor(initialData);

    // Test 1: Split parent paragraph
    moveAndEnter(0, 7);
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Parent ' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'paragraph' }],
      children: initialData[0].children,
    }, initialData[1]]);

    // Test 2: Split first child paragraph
    moveAndEnter(2, 6);
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Parent ' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'paragraph' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child ' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'paragraph 1' }],
        children: [],
      }, initialData[0].children[1]],
    }, initialData[1]]);

    // Test 3: Split last child paragraph and create a new sibling
    moveAndEnter(4, 10);
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Parent ' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'paragraph' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child ' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'paragraph 1' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child para' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'graph 2' }],
        children: [],
      }],
    }, initialData[1]]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/enter-key-behavior-nested-paragraphs');
  });

  it('should handle enter key correctly with toggle_list', () => {
    const initialData: FromBlockJSON[] = [{
      type: 'toggle_list',
      data: {},
      text: [{ insert: 'Toggle list item' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 1' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 2' }],
        children: [],
      }],
    }];

    initializeEditor(initialData);

    // Test 1: Press enter at the end of toggle_list text
    moveAndEnter(0, 16);
    assertJSON([{
      type: 'toggle_list',
      data: {},
      text: [{ insert: 'Toggle list item' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 1' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 2' }],
        children: [],
      }],
    }]);

    // Test 2: Press enter in the middle of toggle_list text
    moveAndEnter(0, 6);
    assertJSON([{
      type: 'toggle_list',
      data: {},
      text: [{ insert: 'Toggle' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: ' list item' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 1' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 2' }],
        children: [],
      }],
    }]);

    // Test 3: Press enter at the start of toggle_list text
    moveAndEnter(0, 0);
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [],
      children: [],
    }, {
      type: 'toggle_list',
      data: {},
      text: [{ insert: 'Toggle' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: ' list item' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 1' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Existing child 2' }],
        children: [],
      }],
    }]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/enter-key-behavior-toggle-list');

  });

  it('should handle enter key correctly with toggle_list is collapsed', () => {
    const collapsedToggleListData: FromBlockJSON[] = [{
      type: 'toggle_list',
      data: { collapsed: true },
      text: [{ insert: 'Collapsed toggle list' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child that should not be inherited' }],
        children: [],
      }],
    }];

    initializeEditor(collapsedToggleListData);

    moveAndEnter(0, 21); // Move to the end of "Collapsed toggle list"
    assertJSON([{
      type: 'toggle_list',
      data: { collapsed: true },
      text: [{ insert: 'Collapsed toggle list' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child that should not be inherited' }],
        children: [],
      }],
    }, {
      type: 'toggle_list',
      data: {},
      text: [],
      children: [],
    }]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/enter-key-behavior-toggle-list-collapsed');
  });

  it('should handle enter key on the empty block but not the paragraph block', () => {
    const initialData: FromBlockJSON[] = [{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First paragraph' }],
      children: [],
    }, {
      type: 'todo_list',
      data: {
        checked: true,
      },
      text: [{ insert: 'Todo list item' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child paragraph' }],
        children: [],
      }],
    }];

    initializeEditor(initialData);

    // Test 1: Press enter at the start of the todo_list block
    moveAndEnter(1, 0);

    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First paragraph' }],
      children: [],
    }, {
      type: 'todo_list',
      data: {
        checked: true,
      },
      text: [],
      children: [],
    }, {
      type: 'todo_list',
      data: {
        checked: true,
      },
      text: [{ insert: 'Todo list item' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child paragraph' }],
        children: [],
      }],
    }]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/enter-key-behavior-empty-block');

    // Test 2: Press enter at the start of the empty todo_list block
    moveAndEnter(1, 0);

    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First paragraph' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [],
      children: [],
    }, {
      type: 'todo_list',
      data: {
        checked: true,
      },
      text: [{ insert: 'Todo list item' }],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Child paragraph' }],
        children: [],
      }],
    }]);
    // Optional: Add visual regression test
    cy.matchImageSnapshot('behavior/enter-key-behavior-empty-block-2');
  });

  describe('Enter key behavior with range selections', () => {
    const simpleInitialData: FromBlockJSON[] = [
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'First paragraph' }],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Second paragraph' }],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Third paragraph' }],
        children: [],
      },
    ];

    const nestedInitialData: FromBlockJSON[] = [
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
            children: [],
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

    it('should handle range selection within a single block', () => {
      initializeEditor(simpleInitialData);
      moveToLineStart(0);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');

      cy.get('@editor').selectText('rst para');
      cy.get('@editor').type('{enter}');

      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Fi' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'graph' }],
          children: [],
        },

        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Second paragraph' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Third paragraph' }],
          children: [],
        },
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-single-block');
    });

    it('should handle range selection across two blocks', () => {
      initializeEditor(simpleInitialData);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');

      cy.selectMultipleText(['st paragraph', 'Second para']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{enter}');

      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Fir' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'graph' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Third paragraph' }],
          children: [],
        },
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-across-blocks');
    });

    it('should handle range selection across same level blocks', () => {
      initializeEditor(nestedInitialData);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');
      cy.selectMultipleText(['paragraph 1', 'Nested paragraph 2']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{enter}');
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
          children: [
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: 'Nested ' }],
              children: [],
            },
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: '.' }],
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
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-same-level-blocks');
    });

    it('should handle range selection with different anchor and focus order', () => {
      initializeEditor(nestedInitialData);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');
      cy.selectMultipleText(['paragraph 1', 'Deeply nested']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{enter}');
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
          children: [
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: 'Nested ' }],
              children: [],
            },
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: ' paragraph' }],
              children: [],
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
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-different-anchor-focus');
    });

    it('should split nested paragraph when selection spans from outer to nested paragraph', () => {
      initializeEditor(nestedInitialData);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');
      cy.selectMultipleText(['ter paragraph', 'Nested paragraph']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{enter}');
      assertJSON([
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Ou' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: ' 1' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Final outer paragraph' }],
          children: [],
        },
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-different-nesting-levels-1');

    });

    it('should split toggle list and maintain nested structure when selection spans multiple nesting levels', () => {
      initializeEditor([{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Outer paragraph' }],
        children: [],
      }, {
        type: 'toggle_list',
        data: {},
        text: [{ insert: 'Toggle list' }],
        children: [
          {
            type: 'paragraph',
            data: {},
            text: [{ insert: 'Nested paragraph' }],
            children: [],
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
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Final outer paragraph' }],
        children: [],
      }]);
      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');
      cy.selectMultipleText(['ed paragraph', 'Nested to']);
      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{enter}');
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
          children: [
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: 'Nest' }],
              children: [],
            },
            {
              type: 'paragraph',
              data: {},
              text: [{ insert: 'ggle list' }],
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
      ]);
      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-different-nesting-levels-2');
    });

    it('should split paragraphs and maintain child structure when selection spans across parent paragraphs', () => {
      const initialData: FromBlockJSON[] = [
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Outer paragraph' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'First parent' }],
          children: [{
            type: 'paragraph',
            data: {},
            text: [{ insert: 'First parent - Child paragraph 1' }],
            children: [],
          }, {
            type: 'paragraph',
            data: {},
            text: [{ insert: 'First parent - Child paragraph 2' }],
            children: [],
          }],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Second parent' }],
          children: [{
            type: 'paragraph',
            data: {},
            text: [{ insert: 'Second parent - Child paragraph 1' }],
            children: [],
          }, {
            type: 'paragraph',
            data: {},
            text: [{ insert: 'Second parent - Child paragraph 2' }],
            children: [],
          }],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Final outer paragraph' }],
          children: [],
        },
      ];

      initializeEditor(initialData);

      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');

      cy.selectMultipleText(['st parent', 'Second ']);

      cy.wait(500);
      cy.get('@editor').focus();

      cy.get('@editor').type('{enter}');

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
          text: [{ insert: 'Fir' }],
          children: [],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'parent' }],
          children: [{
            type: 'paragraph',
            data: {},
            text: [{ insert: 'Second parent - Child paragraph 1' }],
            children: [],
          }, {
            type: 'paragraph',
            data: {},
            text: [{ insert: 'Second parent - Child paragraph 2' }],
            children: [],
          }],
        },
        {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Final outer paragraph' }],
          children: [],
        },
      ]);

      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-different-nesting-levels-3');
    });

    it('should split heading and paragraph while preserving nested structure when selection spans different block types', () => {
      const initialData: FromBlockJSON[] = [{
        type: 'heading',
        data: { level: 1 },
        text: [{ insert: 'Heading 1' }],
        children: [],
      }, {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'First paragraph' }],
        children: [{
          type: 'heading',
          data: { level: 2 },
          text: [{ insert: 'Heading 2' }],
          children: [],
        }, {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Child paragraph' }],
          children: [],
        }],
      }];

      initializeEditor(initialData);

      const selector = '[role="textbox"]';

      cy.get(selector).as('editor');
      cy.selectMultipleText(['ing 1', 'First ']);

      cy.wait(500);
      cy.get('@editor').focus();
      cy.get('@editor').type('{enter}');
      assertJSON([
        {
          type: 'heading',
          data: { level: 1 },
          text: [{ insert: 'Head' }],
          children: [],
        }, {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'paragraph' }],
          children: [],
        }, {
          type: 'heading',
          data: { level: 2 },
          text: [{ insert: 'Heading 2' }],
          children: [],
        }, {
          type: 'paragraph',
          data: {},
          text: [{ insert: 'Child paragraph' }],
          children: [],
        },
      ]);
      // Optional: Add visual regression test
      cy.matchImageSnapshot('behavior/enter-key-behavior-range-selection-different-nesting-levels-4');
    });

  });
});

