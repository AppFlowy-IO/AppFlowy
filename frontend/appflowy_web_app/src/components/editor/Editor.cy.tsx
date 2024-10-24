import { YDoc } from '@/application/types';
import { DocumentTest } from 'cypress/support/document';
import { applyYDoc } from '@/application/ydoc/apply';
import React from 'react';
import * as Y from 'yjs';
import { Editor } from './Editor';
import withAppWrapper from '@/components/main/withAppWrapper';

describe('<Editor />', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
  });
  it('renders with a paragraph', () => {
    const documentTest = new DocumentTest();

    documentTest.insertParagraph('Hello, world!');
    renderEditor(documentTest.doc);
    cy.get('[role="textbox"]').should('contain', 'Hello, world!');
  });

  it('renders with a full document', () => {
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    Object.defineProperty(window.navigator, 'languages', { value: ['en-US'] });
    cy.fixture('full_doc').then((docJson) => {
      const doc = new Y.Doc();
      const state = new Uint8Array(docJson.data.doc_state);

      applyYDoc(doc, state);
      renderEditor(doc);
    });
  });
});

function renderEditor (doc: YDoc) {
  const AppWrapper = withAppWrapper(() => {
    return (
      <div className={'h-screen w-screen overflow-y-auto'}>
        <Editor
          doc={doc}
          readOnly
          viewId={''}
        />
      </div>
    );
  });

  cy.mount(<AppWrapper />);
}
