import { JSDocumentService } from '@/application/services/js-services/document.service';
import { DocumentTest } from '@/../cypress/support/document';
import { nanoid } from 'nanoid';
import React from 'react';
import { Editor } from './Editor';
import withAppWrapper from '@/components/app/withAppWrapper';

describe('<Editor />', () => {
  it('renders with a paragraph', () => {
    const documentTest = new DocumentTest();

    documentTest.insertParagraph('Hello, world!');
    cy.stub(JSDocumentService.prototype, 'openDocument').returns(Promise.resolve(documentTest.doc));
    renderEditor();
    cy.get('[role="textbox"]').should('contain', 'Hello, world!');
  });

  it('renders with a full document', () => {
    cy.mockFullDocument();
    renderEditor();
  });
});

function renderEditor() {
  const documentId = nanoid(8);
  const workspaceId = nanoid(8);

  const AppWrapper = withAppWrapper(() => {
    return (
      <div className={'h-screen w-screen overflow-y-auto'}>
        <Editor documentId={documentId} readOnly workspaceId={workspaceId} />
      </div>
    );
  });

  cy.mount(<AppWrapper />);
}
