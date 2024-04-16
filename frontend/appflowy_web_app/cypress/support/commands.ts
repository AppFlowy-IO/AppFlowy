/// <reference types="cypress" />
// ***********************************************
// This example commands.ts shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
//
// -- This is a parent command --
// Cypress.Commands.add('login', (email, password) => { ... })
//
//
// -- This is a child command --
// Cypress.Commands.add('drag', { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add('dismiss', { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite('visit', (originalFn, url, options) => { ... })
//

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
Cypress.Commands.add('mockAPI', () => {
  cy.fixture('sign_in_success').then((json) => {
    cy.intercept('GET', `/api/user/verify/${json.access_token}`, {
      fixture: 'verify_token',
    }).as('verifyToken');
    cy.intercept('POST', '/gotrue/token?grant_type=password', json).as('loginSuccess');
    cy.intercept('POST', '/gotrue/token?grant_type=refresh_token', json).as('refreshToken');
  });
  cy.intercept('GET', '/api/user/profile', { fixture: 'user' }).as('getUserProfile');
});

// Example use:
// beforeEach(() => {
//   cy.mockAPI();
// });

