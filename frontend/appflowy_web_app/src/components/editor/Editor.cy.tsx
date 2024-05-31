import { YDoc, YFolder, YjsEditorKey } from '@/application/collab.type';
import { DocumentTest } from '@/../cypress/support/document';
import { applyYDoc } from '@/application/ydoc/apply';
import { FolderProvider } from '@/components/_shared/context-provider/FolderProvider';
import React from 'react';
import * as Y from 'yjs';
import { Editor } from './Editor';
import withAppWrapper from '@/components/app/withAppWrapper';

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
    cy.mockDatabase();
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    Object.defineProperty(window.navigator, 'languages', { value: ['en-US'] });
    cy.fixture('folder').then((folderJson) => {
      const doc = new Y.Doc();
      const state = new Uint8Array(folderJson.data.doc_state);
      applyYDoc(doc, state);
      const folder = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.folder) as YFolder;
      cy.fixture('full_doc').then((docJson) => {
        const doc = new Y.Doc();
        const state = new Uint8Array(docJson.data.doc_state);

        applyYDoc(doc, state);
        renderEditor(doc, folder);
      });
    });
  });
});

function renderEditor(doc: YDoc, folder?: YFolder) {
  const AppWrapper = withAppWrapper(() => {
    return (
      <div className={'h-screen w-screen overflow-y-auto'}>
        {folder ? (
          <FolderProvider folder={folder}>
            <Editor doc={doc} readOnly />
          </FolderProvider>
        ) : (
          <Editor doc={doc} readOnly />
        )}
      </div>
    );
  });

  cy.mount(<AppWrapper />);
}
