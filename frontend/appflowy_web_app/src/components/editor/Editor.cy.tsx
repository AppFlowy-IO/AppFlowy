import { YDoc } from '@/application/collab.type';
import { DocumentTest } from '@/../cypress/support/document';
import { applyYDoc } from '@/application/ydoc/apply';
import React from 'react';
import * as Y from 'yjs';
import { Editor } from './Editor';
import withAppWrapper from '@/components/app/withAppWrapper';

describe('<Editor />', () => {
  it('renders with a paragraph', () => {
    const documentTest = new DocumentTest();

    documentTest.insertParagraph('Hello, world!');
    renderEditor(documentTest.doc);
    cy.get('[role="textbox"]').should('contain', 'Hello, world!');
  });

  it('renders with a full document', () => {
    cy.fixture('full_doc').then((docJson) => {
      const doc = new Y.Doc();
      const state = new Uint8Array(docJson.data.doc_state);

      applyYDoc(doc, state);
      renderEditor(doc);
    });
  });
});

function renderEditor(doc: YDoc) {
  const AppWrapper = withAppWrapper(() => {
    return (
      <div className={'h-screen w-screen overflow-y-auto'}>
        <Editor doc={doc} readOnly />
      </div>
    );
  });

  cy.mount(<AppWrapper />);
}
