import { getModKey, initialEditorTest } from '@/components/editor/__tests__/mount';
import { FromBlockJSON } from 'cypress/support/document';

const initialData: FromBlockJSON[] = [{
  type: 'paragraph',
  data: {},
  text: [{ insert: 'First paragraph' }],
  children: [],
}];

const { assertJSON, initializeEditor, getFinalJSON } = initialEditorTest();

describe('BlockControls', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    initializeEditor(initialData);
    const selector = '[role="textbox"]';

    cy.get(selector).as('editor');
    cy.wait(1000);
  });

  const hoverControls = () => {
    cy.get('@editor').get('[data-block-type="paragraph"]').as('block');
    cy.get('@block').should('exist');
    cy.get('@editor').realHover({
      position: 'center',
      pointer: 'mouse',
    });
    cy.wait(200);
    cy.get('@block').realMouseMove(10, 10);
    cy.get('@editor').get('[data-testid="hover-controls"]').as('controls');
  };

  const openControlsMenu = () => {
    hoverControls();
    cy.wait(100);
    cy.get('@controls').get('[data-testid="open-block-options"]').as('open-block-options');
    cy.get('@open-block-options').click();
    cy.get('[data-testid="controls-menu"]').as('menu');
  };

  it('should show block controls when hovering over a block', () => {
    hoverControls();
    cy.get('@controls').should('be.visible');
  });

  it('should add below when clicking on the add button', () => {
    let expectedJson: FromBlockJSON[] = initialData;

    hoverControls();
    cy.wait(100);
    cy.get('@controls').get('[data-testid="add-block"]').as('add-block');
    cy.get('@add-block').click();

    expectedJson = [expectedJson[0], {
      type: 'paragraph',
      data: {},
      text: [],
      children: [],
    }];

    assertJSON(expectedJson);
  });

  it('should add above when clicking on the add button with altKey=true', () => {
    let expectedJson: FromBlockJSON[] = initialData;

    hoverControls();
    cy.wait(100);
    cy.get('@controls').get('[data-testid="add-block"]').as('add-block');
    cy.get('@add-block').click({ altKey: true });

    expectedJson = [{
      type: 'paragraph',
      data: {},
      text: [],
      children: [],
    }, expectedJson[0]];

    assertJSON(expectedJson);
  });

  it('should open block menu when clicking on the menu button', () => {
    openControlsMenu();
    cy.get('@menu').should('be.visible');
  });

  it('should duplicate block when clicking on the duplicate option', () => {
    openControlsMenu();
    cy.get('@menu').get('[data-testid="duplicate"]').as('duplicate');
    cy.get('@duplicate').click();

    let expectedJson: FromBlockJSON[] = initialData;
    expectedJson = [expectedJson[0], expectedJson[0]];

    assertJSON(expectedJson);
  });

  it('should copy link to block when clicking on the copy link to block option', () => {
    let expectedJson: FromBlockJSON[] = initialData;
    openControlsMenu();
    cy.get('@menu').get('[data-testid="copyLinkToBlock"]').as('copyLinkToBlock');
    cy.get('@copyLinkToBlock').click();

    cy.get('[data-testid="controls-menu"]').should('not.exist');

    cy.selectMultipleText(['First paragraph']);
    cy.wait(100);
    cy.realPress(['ArrowRight']);

    cy.realPress(['Enter']);
    cy.wait(100);
    const meta = getModKey();
    cy.realPress([meta, 'v']);

    cy.wrap(null).then(() => {
      const finalJson = getFinalJSON();
      expect(finalJson).to.have.length(2);
      expect(finalJson[1].type).to.equal('paragraph');
      expect(finalJson[1].data).to.deep.equal({});
      expect(finalJson[1].children).to.deep.equal([]);
      expect(finalJson[1].text[0].insert).to.equal('@');
      expect(finalJson[1].text[0].attributes?.mention).to.has.keys('type', 'page_id', 'block_id');

    });

  });

  it('should delete block when clicking on the delete option', () => {
    openControlsMenu();
    cy.get('@menu').get('[data-testid="delete"]').as('delete');
    cy.get('@delete').click();

    assertJSON([{
      type: 'paragraph',
      data: {},
      text: [],
      children: [],
    }]);
  });
});