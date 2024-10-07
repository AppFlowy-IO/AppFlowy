import { initialEditorTest, mountEditor, moveCursor } from '@/components/editor/__tests__/mount';
import { DocumentTest, FromBlockJSON } from 'cypress/support/document';

describe('<Paragraph />', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
  });

  it('render paragraph', () => {
    cy.fixture<FromBlockJSON[]>('editor/blocks/paragraph').then((data) => {
      const documentTest = new DocumentTest();

      documentTest.fromJSON(data);
      mountEditor({ readOnly: true, doc: documentTest.doc });
    }).as('render');
    cy.get('[role="textbox"]').should('exist');
    cy.get('[data-block-type="paragraph"]').should('have.length', 7);
    cy.get('[role="textbox"]').children().should('have.length', 3);
    cy.matchImageSnapshot('paragraph/initial-render');
  });

  it('edit paragraph text', () => {
    const { assertJSON, initializeEditor } = initialEditorTest();

    const data: FromBlockJSON[] = [{
      type: 'paragraph',
      data: {},
      text: [
        { insert: 'Hello, ' },
        {
          insert: 'world!', 'attributes': {
            'italic': true,
            'underline': true,
            'strikethrough': true,
            'font_color': '#ff0000',
            'bg_color': '#00ff00',
          },
        },
        { insert: ' This is a ' },
        {
          insert: 'bold', 'attributes': {
            'bold': true,
          },
        },
        { insert: ' text.' },
      ],
      children: [],
    }];

    initializeEditor(data);

    cy.get('[role="textbox"]').should('exist');

    cy.get('[role="textbox"]').type('{movetostart}').type('{rightarrow}'.repeat(10))
      .type(` New text at the 'world' middle `);
    cy.get('[role="textbox"]').type('{movetoend}').type('{leftarrow}'.repeat(6)).type('{backspace}'.repeat(4));

    const expectJSON = [{
      type: 'paragraph',
      data: {},
      text: [
        { insert: 'Hello, ' },
        {
          insert: `wor New text at the 'world' middle ld!`,
          attributes: {
            italic: true,
            underline: true,
            strikethrough: true,
            font_color: '#ff0000',
            bg_color: '#00ff00',
          },
        },
        { insert: ' This is a  text.' },
      ],
      children: [],
    }];
    assertJSON(expectJSON);
    // Optional: Add visual regression test
    cy.matchImageSnapshot('paragraph/editing-text');
  });

  it('edit paragraphs with undo and redo', () => {
    const { assertJSON, initializeEditor } = initialEditorTest();
    const initialData: FromBlockJSON[] = [{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Hello, world!' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [{ insert: 'Hello, world! New at the end' }],
      children: [],
    }];

    initializeEditor(initialData);

    cy.get('[role="textbox"]').should('exist');

    // Initial edit: Add text to the end of the second paragraph
    cy.get('[role="textbox"]').children().eq(1).type('{movetoend} More text');

    // Check the result of the initial edit
    assertJSON([
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hello, world!' }],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hello, world! New at the end More text' }],
        children: [],
      },
    ]);

    // Perform undo operation
    if (Cypress.platform === 'darwin') {
      cy.get('body').type('{cmd}z');
    } else {
      cy.get('body').type('{ctrl}z');
    }

    // Check the result after undo
    assertJSON(initialData);

    // Perform redo operation
    if (Cypress.platform === 'darwin') {
      cy.get('body').type('{cmd}{shift}z');
    } else {
      cy.get('body').type('{ctrl}y');
    }

    // Check the result after redo
    assertJSON([
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hello, world!' }],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hello, world! New at the end More text' }],
        children: [],
      },
    ]);

    // Perform additional edits: Modify the first paragraph
    cy.get('[role="textbox"]').children().eq(0).type('{selectall}').type('{rightarrow}').type(' Additional content');

    // Check the final result
    assertJSON([
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hello, world! Additional content' }],
        children: [],
      },
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'Hello, world! New at the end More text' }],
        children: [],
      },
    ]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('paragraph/editing-text-with-undo-redo');
  });

  it('render inline formatting', () => {
    const { assertJSON, initializeEditor } = initialEditorTest();
    const data: FromBlockJSON[] = [{
      type: 'paragraph',
      data: {},
      text: [
        { insert: 'Hello, ' },
        {
          insert: 'world!', 'attributes': {
            'italic': true,
            'underline': true,
            'strikethrough': true,
            'font_color': '#ff0000',
            'bg_color': '#00ff00',
          },
        },
        { insert: ' This is a ' },
        {
          insert: 'bold', 'attributes': {
            'bold': true,
          },
        },
        { insert: ' text.' },
      ],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [
        { insert: 'This is a date: ' },
        { insert: '@', attributes: { mention: { type: 'date', 'date': Date.now().valueOf() } } },
        { insert: 'This is a formula: ' },
        { insert: '$', attributes: { formula: 'E=mc^2' } },
        { insert: ' .' },
      ],
      children: [],
    }];

    initializeEditor(data);

    moveCursor(1, 17);
    cy.get('[role="textbox"]').realPress(' ');
    let expectJSON = [
      data[0],
      {
        ...data[1],
        text: [
          ...data[1].text.slice(0, 2),
          { insert: ' This is a formula: ' },
          { insert: '$', attributes: { formula: 'E=mc^2' } },
          { insert: ' .' },
        ],
      },
    ];
    assertJSON(expectJSON);

    cy.wait(500);
    moveCursor(1, 38);
    cy.get('[role="textbox"]').type(' end');
    expectJSON = [
      expectJSON[0],
      {
        ...expectJSON[1],
        text: [
          ...expectJSON[1].text.slice(0, -1),
          { insert: ' end .' },
        ],
      },
    ];
    assertJSON(expectJSON);

    cy.wait(500);
    cy.realPress(['ArrowUp', 'ArrowUp']);
    cy.get('[role="textbox"]').type(' first line end.');
    expectJSON = [
      {
        ...expectJSON[0], text: [
          ...expectJSON[0].text.slice(0, -1),
          { insert: ' text. first line end.' },
        ],
      },
      expectJSON[1],
    ];
    assertJSON(expectJSON);
    // Optional: Add visual regression test
    cy.matchImageSnapshot('paragraph/inline-formatting');

  });

});

export {};