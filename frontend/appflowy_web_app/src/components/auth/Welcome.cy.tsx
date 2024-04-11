import React from 'react';
import Welcome from './Welcome';
import withAppWrapper from '@/withAppWrapper';

describe('<Welcome />', () => {
  beforeEach(() => {
    cy.mockAPI();
  });
  
  it('renders', () => {
    const AppWrapper = withAppWrapper(Welcome);
    cy.mount(<AppWrapper />);
  });

  it('should handle login success', () => {

    const AppWrapper = withAppWrapper(Welcome);
    cy.mount(<AppWrapper />);
    cy.get('[data-cy=signInWithEmail]').click();
    cy.wait(100);
    cy.get('[data-cy=signInWithEmailDialog]').as('dialog').should('be.visible');
    cy.get('[data-cy=email]').type('fakeEmail123');
    cy.get('[data-cy=password]').type('fakePassword123');
    cy.get('[data-cy=submit]').click();
    cy.wait('@loginSuccess');
    cy.wait('@verifyToken');
    cy.wait('@getUserProfile');
    cy.get('@dialog').should('not.exist');
  });
});