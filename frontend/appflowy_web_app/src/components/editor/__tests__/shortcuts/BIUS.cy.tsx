import { mountEditor } from '@/components/editor/__tests__/mount';
import { DocumentTest, FromBlockJSON } from 'cypress/support/document';

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

const getModKey = () => {
  if (Cypress.platform === 'darwin') {
    return 'Meta';
  } else {
    return 'Control';
  }
};

describe('BIUS.cy', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');
  });

  it('should handle `Mod+B/I/U` and `Mod + Shift + S` key press', () => {
    cy.selectMultipleText(['ter parag']);
    cy.get('@editor').focus();
    cy.get('@editor').realPress([getModKey(), 'b']);
    cy.get('@editor').realPress([getModKey(), 'i']);
    cy.get('@editor').realPress([getModKey(), 'u']);
    cy.get('@editor').realPress([getModKey(), 'Shift', 's']);
    assertJSON([
      {
        ...initialData[0],
        text: [{ insert: 'Ou' }, {
          insert: 'ter parag',
          attributes: { bold: true, italic: true, underline: true, strikethrough: true },
        }, { insert: 'raph' }],
      },
      initialData[1],
      initialData[2],
    ]);

    cy.selectMultipleText(['sted toggle list', 'paragraph 2']);
    cy.get('@editor').realPress([getModKey(), 'b']);
    cy.get('@editor').realPress([getModKey(), 'i']);
    cy.get('@editor').realPress([getModKey(), 'u']);
    cy.get('@editor').realPress([getModKey(), 'Shift', 's']);
    assertJSON([
      {
        ...initialData[0],
        text: [{ insert: 'Ou' }, {
          insert: 'ter parag',
          attributes: { bold: true, italic: true, underline: true, strikethrough: true },
        }, { insert: 'raph' }],
      },
      {
        ...initialData[1],
        children: [
          initialData[1].children[0],
          {
            type: 'toggle_list',
            data: {},
            text: [{ insert: 'Ne' }, {
              insert: 'sted toggle list',
              attributes: { bold: true, italic: true, underline: true, strikethrough: true },
            }],
            children: [
              {
                type: 'paragraph',
                data: {},
                text: [{
                  insert: 'Deeply nested paragraph',
                  attributes: { bold: true, italic: true, underline: true, strikethrough: true },
                }],
                children: [],
              },
            ],
          },
          {
            type: 'paragraph',
            data: {},
            text: [{
              insert: 'Nested paragraph 2',
              attributes: { bold: true, italic: true, underline: true, strikethrough: true },
            }, { insert: '.' }],
            children: [],
          },
        ],
      },
      initialData[2],
    ]);

    // Optional: Add visual regression test
    cy.matchImageSnapshot('shortcuts/BIUS.cy');
  });
});