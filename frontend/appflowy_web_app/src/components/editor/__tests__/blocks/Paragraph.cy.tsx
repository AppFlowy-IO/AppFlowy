import { mountEditor } from '@/components/editor/__tests__/mount';
import { DocumentTest, FromBlockJSON } from 'cypress/support/document';

describe('<Paragraph />', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
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

    cy.fixture<FromBlockJSON[]>('editor/blocks/paragraph').then((data) => {
      documentTest.fromJSON(data);
      mountEditor({ readOnly: false, doc: documentTest.doc });
    }).as('documentTest');
    cy.get('[role="textbox"]').should('exist');
    cy.get('[role="textbox"]').type('{selectall}').type('{rightarrow}')
      .type('New text at the end');
    cy.get('[role="textbox"]')
      .type('{movetoend}')
      .type('{leftarrow}'.repeat(10))
      .type('{backspace}'.repeat(5)).type('add').type('{backspace}'.repeat(2));
    cy.matchImageSnapshot('paragraph/editing-text');

    cy.then(() => {
      console.log('====', documentTest.doc.getMap('data').toJSON());
    });
  });
});

export {};