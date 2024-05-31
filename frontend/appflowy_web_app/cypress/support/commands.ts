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

import { YDoc } from '@/application/collab.type';
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import { JSDatabaseService } from '@/application/services/js-services/database.service';
import { JSDocumentService } from '@/application/services/js-services/document.service';
import { applyYDoc } from '@/application/ydoc/apply';
import * as Y from 'yjs';

Cypress.Commands.add('mockAPI', () => {
  cy.fixture('sign_in_success').then((json) => {
    cy.intercept('GET', `/api/user/verify/${json.access_token}`, {
      fixture: 'verify_token',
    }).as('verifyToken');
    cy.intercept('POST', '/gotrue/token?grant_type=password', json).as('loginSuccess');
    cy.intercept('POST', '/gotrue/token?grant_type=refresh_token', json).as('refreshToken');
  });
  cy.intercept('GET', '/api/user/profile', { fixture: 'user' }).as('getUserProfile');
  cy.intercept('GET', '/api/user/workspace', { fixture: 'user_workspace' }).as('getUserWorkspace');
});

// Example use:
// beforeEach(() => {
//   cy.mockAPI();
// });

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
Cypress.Commands.add('mockCurrentWorkspace', () => {
  cy.fixture('current_workspace').then((workspace) => {
    cy.stub(JSDatabaseService.prototype, 'currentWorkspace').resolves(workspace);
  });
});

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
Cypress.Commands.add('mockGetWorkspaceDatabases', () => {
  cy.fixture('database/databases').then((databases) => {
    cy.stub(JSDatabaseService.prototype, 'getWorkspaceDatabases').resolves(databases);
  });
});

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
Cypress.Commands.add('mockDatabase', () => {
  cy.mockCurrentWorkspace();
  cy.mockGetWorkspaceDatabases();

  const ids = [
    '4c658817-20db-4f56-b7f9-0637a22dfeb6',
    'ce267d12-3b61-4ebb-bb03-d65272f5f817',
    'ad7dc45b-44b5-498f-bfa2-0f43bf05cc0d',
  ];

  const mockOpenDatabase = cy.stub(JSDatabaseService.prototype, 'openDatabase');

  ids.forEach((id) => {
    cy.fixture(`database/${id}`).then((database) => {
      cy.fixture(`database/rows/${id}`).then((rows) => {
        const doc = new Y.Doc();
        const rootRowsDoc = new Y.Doc();
        const rowsFolder: Y.Map<YDoc> = rootRowsDoc.getMap();
        const databaseState = new Uint8Array(database.data.doc_state);

        applyYDoc(doc, databaseState);

        Object.keys(rows).forEach((key) => {
          const data = rows[key];
          const rowDoc = new Y.Doc();

          applyYDoc(rowDoc, new Uint8Array(data));
          rowsFolder.set(key, rowDoc);
        });
        mockOpenDatabase.withArgs(id).resolves({
          databaseDoc: doc,
          rows: rowsFolder,
        });
      });
    });
  });
});

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
Cypress.Commands.add('mockDocument', (id: string) => {
  cy.fixture(`document/${id}`).then((subDocument) => {
    const doc = new Y.Doc();
    const state = new Uint8Array(subDocument.data.doc_state);

    applyYDoc(doc, state);

    cy.stub(JSDocumentService.prototype, 'openDocument').withArgs(id).resolves(doc);
  });
});
