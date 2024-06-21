import { renderDatabase } from '@/components/database/__tests__/withTestingDatabase';
import '@/components/layout/layout.scss';

describe('<Database /> with filters and sorts', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    cy.mockDatabase();
  });

  it('render a database with filters and sorts', () => {
    const onNavigateToView = cy.stub();

    renderDatabase(
      {
        onNavigateToView,
        databaseId: '87bc006e-c1eb-47fd-9ac6-e39b17956369',
        viewId: '7f233be4-1b4d-46b2-bcfc-f341b8d75267',
      },
      () => {
        cy.wait(1000);
        cy.getTestingSelector('database-actions-filter').click();

        cy.get('.database-conditions').then(($el) => {
          cy.wait(500);
          const height = $el.height();

          expect(height).to.be.greaterThan(0);
        });

        cy.getTestingSelector('database-sort-condition').click();
        cy.wait(500);
        cy.getTestingSelector('sort-condition').as('sortConditions').should('have.length', 2);
        cy.get('@sortConditions').eq(0).contains('number');
        cy.get('@sortConditions').eq(0).contains('Ascending');
        cy.get('@sortConditions').eq(1).contains('Name');
        cy.get('@sortConditions').eq(1).contains('Descending');
        cy.clickOutside();
        cy.getTestingSelector('sort-condition-list').should('not.exist');

        // the length of filters should be 6
        cy.getTestingSelector('database-filter-condition').as('filterConditions');
        cy.get('@filterConditions').should('have.length', 6);
        // the first filter should be 'Name', the value should be 'contains', and the input should be 123
        cy.get('@filterConditions').eq(0).as('filterCondition');
        cy.get('@filterCondition').contains('Name');
        cy.get('@filterCondition').contains('123');
        cy.get('@filterCondition').click();
        cy.getTestingSelector('filter-menu-popover').should('be.visible');
        cy.getTestingSelector('filter-condition-type').contains('Contains');
        cy.get(`[data-testid="text-filter-input"] input`).should('have.value', '123');
        cy.clickOutside();
        // the second filter should be 'Type', the value should be 'is not empty'
        cy.get('@filterConditions').eq(1).as('filterCondition');
        cy.get('@filterCondition').contains('Type');
        cy.get('@filterCondition').contains('is not empty');
        cy.get('@filterCondition').click();
        cy.clickOutside();
        // the third filter should be 'Done', the value should be 'is Checked'
        cy.get('@filterConditions').eq(2).as('filterCondition');
        cy.get('@filterCondition').contains('Done');
        cy.get('@filterCondition').contains('is Checked');
        cy.get('@filterCondition').click();
        cy.clickOutside();
        // the fourth filter should be 'Number', the value should be 'is greater than', and the input should be 600
        cy.get('@filterConditions').eq(3).as('filterCondition');
        cy.get('@filterCondition').contains('number');
        cy.get('@filterCondition').contains('> 600');
        cy.get('@filterCondition').click();
        cy.getTestingSelector('filter-menu-popover').should('be.visible');
        cy.getTestingSelector('filter-condition-type').contains('Is greater than');
        cy.get(`[data-testid="number-filter-input"] input`).should('have.value', '600');
        cy.clickOutside();
        // the fifth filter should be 'multi type', the value should be 'Does not contain'
        cy.get('@filterConditions').eq(4).as('filterCondition');
        cy.get('@filterCondition').contains('multi type');
        cy.get('@filterCondition').click();
        cy.getTestingSelector('filter-menu-popover').should('be.visible');
        cy.getTestingSelector('filter-condition-type').contains('Does not contain');
        cy.getTestingSelector('select-option-list').as('selectOptionList');
        cy.get('@selectOptionList').should('have.length', 2);
        cy.get('@selectOptionList').eq(0).contains('option-2');
        cy.get('@selectOptionList').eq(1).contains('option-1');
        cy.get('@selectOptionList').eq(1).should('have.data', 'checked', true);
        cy.clickOutside();
        // the sixth filter should be 'Checklist', the value should be 'is completed'
        cy.get('@filterConditions').eq(5).as('filterCondition');
        cy.get('@filterCondition').contains('Checklist');
        cy.get('@filterCondition').contains('is complete');
        cy.get('@filterCondition').click();
        cy.clickOutside();

        cy.getTestingSelector('view-tab-a734a068-e73d-4b4b-853c-4daffea389c0').click();
        cy.wait(800);
        cy.getTestingSelector('view-tab-7f233be4-1b4d-46b2-bcfc-f341b8d75267').click();
      }
    );
  });
});
