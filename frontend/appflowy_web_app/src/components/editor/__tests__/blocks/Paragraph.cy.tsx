import { mountEditor } from '@/components/editor/__tests__/mount';
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
    const documentTest = new DocumentTest();
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

    documentTest.fromJSON(data);

    mountEditor({ readOnly: false, doc: documentTest.doc });

    cy.get('[role="textbox"]').should('exist');

    cy.get('[role="textbox"]').type('{movetostart}').type('{rightarrow}'.repeat(10))
      .type(' New text at the `world` middle ');
    cy.get('[role="textbox"]').type('{movetoend}').type('{leftarrow}'.repeat(6)).type('{backspace}'.repeat(4));

    cy.wrap(null).then(() => {
      const finalJSON = documentTest.toJSON();
      const expectJSON = [{
        type: 'paragraph',
        data: {},
        text: [
          { insert: 'Hello, ' },
          {
            insert: 'wor New text at the `world` middle ld!',
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

      expect(finalJSON).to.deep.equal(expectJSON);
    });
    // Optional: Add visual regression test
    cy.matchImageSnapshot('paragraph/editing-text');
  });

  it('edit paragraphs with undo and redo', () => {
    const documentTest = new DocumentTest();
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

    documentTest.fromJSON(initialData);
    mountEditor({ readOnly: false, doc: documentTest.doc });

    cy.get('[role="textbox"]').should('exist');

    // Initial edit: Add text to the end of the second paragraph
    cy.get('[role="textbox"]').children().eq(1).type('{movetoend} More text');

    // Check the result of the initial edit
    cy.wrap(null).then(() => {
      const editedJSON = documentTest.toJSON();
      const expectedEditedJSON = [
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
      ];

      expect(editedJSON).to.deep.equal(expectedEditedJSON);
    });

    // Perform undo operation
    if (Cypress.platform === 'darwin') {
      cy.get('body').type('{cmd}z');
    } else {
      cy.get('body').type('{ctrl}z');
    }

    // Check the result after undo
    cy.wrap(null).then(() => {
      const undoneJSON = documentTest.toJSON();

      expect(undoneJSON).to.deep.equal(initialData);
    });

    // Perform redo operation
    if (Cypress.platform === 'darwin') {
      cy.get('body').type('{cmd}{shift}z');
    } else {
      cy.get('body').type('{ctrl}y');
    }

    // Check the result after redo
    cy.wrap(null).then(() => {
      const redoneJSON = documentTest.toJSON();
      const expectedRedoneJSON = [
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
      ];

      expect(redoneJSON).to.deep.equal(expectedRedoneJSON);
    });

    // Perform additional edits: Modify the first paragraph
    cy.get('[role="textbox"]').children().eq(0).type('{selectall}').type('{rightarrow}').type(' Additional content');

    // Check the final result
    cy.wrap(null).then(() => {
      const finalJSON = documentTest.toJSON();
      const expectedFinalJSON = [
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
      ];

      expect(finalJSON).to.deep.equal(expectedFinalJSON);
    });

    // Optional: Add visual regression test
    cy.matchImageSnapshot('paragraph/editing-text-with-undo-redo');
  });

  it('render inline formatting', () => {
    const documentTest = new DocumentTest();
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

    documentTest.fromJSON(data);
    mountEditor({ readOnly: false, doc: documentTest.doc });

    // Optional: Add visual regression test
    cy.matchImageSnapshot('paragraph/inline-formatting');

  });

});

export {};