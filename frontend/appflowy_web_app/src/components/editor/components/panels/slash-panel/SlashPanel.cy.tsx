import { getModKey, initialEditorTest, moveCursor } from '@/components/editor/__tests__/mount';
import { FromBlockJSON } from 'cypress/support/document';

const initialData: FromBlockJSON[] = [{
  type: 'paragraph',
  data: {},
  text: [{ insert: 'First paragraph' }],
  children: [],
}];

const { assertJSON, initializeEditor } = initialEditorTest();

describe('SlashPanel', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');
    cy.wait(1000);
  });

  const hoverControls = (index: number) => {
    cy.get('@editor').get('[data-block-type]').eq(index).as('block');
    cy.get('@block').should('exist');
    cy.get('@editor').realHover({
      position: 'center',
      pointer: 'mouse',
    });
    cy.wait(200);
    cy.get('@block').realMouseMove(10, 10);
    cy.get('@editor').get('[data-testid="hover-controls"]').as('controls');
  };

  it('should open slash panel when add block button is clicked', () => {
    hoverControls(0);
    cy.get('@controls').get('[data-testid="add-block"]').click();
    cy.get('@editor').get('[data-block-type="paragraph"]').should('have.length', 2);
    cy.get('[data-testid="slash-panel"]').as('slashPanel');
    cy.get('@slashPanel').should('exist');
    cy.get('@slashPanel').get('[data-option-key="code"]').click();
    cy.wait(200);
    cy.get('@slashPanel').should('not.exist');
    assertJSON([
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'First paragraph' }],
        children: [],
      },
      {
        type: 'code',
        data: {},
        text: [],
        children: [],
      },
    ]);

    hoverControls(0);
    cy.get('@controls').get('[data-testid="add-block"]').click();
    cy.wait(500);
    cy.get('@controls').realPress('Escape');
    cy.wait(500);
    hoverControls(1);
    cy.get('@controls').get('[data-testid="add-block"]').click();
    cy.get('@editor').get('[data-block-type]').should('have.length', 3);
    cy.get('[data-testid="slash-panel"]').as('slashPanel');
    cy.get('@slashPanel').should('exist');
    cy.get('@slashPanel').get('[data-option-key="heading3"]').click();
    cy.wait(200);
    cy.get('@slashPanel').should('not.exist');
    assertJSON([
      {
        type: 'paragraph',
        data: {},
        text: [{ insert: 'First paragraph' }],
        children: [],
      },
      {
        type: 'heading',
        data: { level: 3 },
        text: [],
        children: [],
      },
      {
        type: 'code',
        data: {},
        text: [],
        children: [],
      },
    ]);
  });

  it('should open slash panel when \'/\' is typed', () => {
    cy.get('@editor').focus();
    moveCursor(0, 5);
    cy.get('@editor').realType(' /');
    cy.get('[data-testid="slash-panel"]').as('slashPanel');
    cy.get('@slashPanel').should('exist');
    cy.get('@editor').realPress('Escape');
    cy.get('@slashPanel').should('not.exist');
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First / paragraph' }],
      children: [],
    }]);
    cy.get('@editor').realPress('Backspace');
    cy.get('@editor').realType('/');
    cy.get('@slashPanel').should('exist');
    cy.get('@slashPanel').get('[data-option-key="text"]').click();
    cy.wait(200);
    cy.get('@slashPanel').should('not.exist');
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First  paragraph' }],
      children: [],
    }, {
      type: 'paragraph',
      data: {},
      text: [],
      children: [],
    }]);

    cy.get('@editor').realType('child paragraph');
    cy.get('@editor').realPress(['ArrowUp']);
    cy.get('@editor').realType('/');
    cy.get('@slashPanel').should('exist');
    cy.get('@editor').realType('toggle');
    cy.get('@slashPanel').get('[data-option-key="toggleHeading2"]').click();
    cy.wait(200);
    cy.get('@slashPanel').should('not.exist');
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First  paragraph' }],
      children: [],
    }, {
      type: 'toggle_list',
      data: {
        level: 2,
        collapsed: false,
      },
      text: [],
      children: [{
        type: 'paragraph',
        data: {},
        text: [{ insert: 'child paragraph' }],
        children: [],
      }],
    }]);
  });

  it('should close slash panel when escape is pressed', () => {
    cy.get('@editor').focus();
    moveCursor(0, 5);
    cy.get('@editor').realType('/');
    cy.get('[data-testid="slash-panel"]').as('slashPanel');
    cy.get('@slashPanel').should('exist');
    cy.get('@editor').realPress('Escape');
    cy.get('@slashPanel').should('not.exist');
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First/ paragraph' }],
      children: [],
    }]);
  });

  it('should close slash panel when deleting \'/\'', () => {
    cy.get('@editor').focus();
    moveCursor(0, 5);
    cy.get('@editor').realType('/');
    cy.get('[data-testid="slash-panel"]').as('slashPanel');
    cy.get('@editor').realType('text');
    cy.get('@slashPanel').should('exist');
    cy.get('@editor').realPress('Backspace');
    cy.get('@slashPanel').should('exist');
    cy.get('@editor').realPress(['Backspace', 'Backspace', 'Backspace', 'Backspace']);
    cy.get('@slashPanel').should('not.exist');
    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [{ insert: 'First paragraph' }],
      children: [],
    }]);
  });

  it('should close slash panel when pressing backspace', () => {
    hoverControls(0);
    cy.get('@controls').get('[data-testid="add-block"]').click();
    cy.wait(500);
    cy.get('[data-testid="slash-panel"]').as('slashPanel');
    cy.get('@controls').realPress('Backspace');
    cy.get('[data-testid="slash-panel"]').should('not.exist');
    assertJSON(initialData);
  });
});