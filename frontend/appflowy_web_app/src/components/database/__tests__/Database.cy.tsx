import { renderDatabase } from '@/components/database/__tests__/withTestingDatabase';
import '@/components/layout/layout.scss';

describe('<Database />', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    cy.mockDatabase();
  });

  it('renders with a database', () => {
    const onNavigateToView = cy.stub();

    renderDatabase(
      {
        databaseId: '4c658817-20db-4f56-b7f9-0637a22dfeb6',
        viewId: '7d2148fc-cace-4452-9c5c-96e52e6bf8b5',
        onNavigateToView,
      },
      () => {
        cy.get('[data-testid^=view-tab-]').should('have.length', 4);
        cy.get('.database-grid').should('exist');

        cy.get('[data-testid=view-tab-e410747b-5f2f-45a0-b2f7-890ad3001355]').click();
        cy.get('.database-board').should('exist');
        cy.wrap(onNavigateToView).should('have.been.calledOnceWith', 'e410747b-5f2f-45a0-b2f7-890ad3001355');

        cy.wait(800);
        cy.get('[data-testid=view-tab-7d2148fc-cace-4452-9c5c-96e52e6bf8b5]').click();
        cy.get('.database-grid').should('exist');
        cy.wrap(onNavigateToView).should('have.been.calledWith', '7d2148fc-cace-4452-9c5c-96e52e6bf8b5');

        cy.wait(800);
        cy.get('[data-testid=view-tab-2143e95d-5dcb-4e0f-bb2c-50944e6e019f]').click();
        cy.get('.database-calendar').should('exist');
        cy.wrap(onNavigateToView).should('have.been.calledWith', '2143e95d-5dcb-4e0f-bb2c-50944e6e019f');
      }
    );
  });
});
