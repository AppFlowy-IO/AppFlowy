import { YDoc, YFolder, YjsEditorKey } from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import { FolderProvider } from '@/components/_shared/context-provider/FolderProvider';
import { IdProvider } from '@/components/_shared/context-provider/IdProvider';
import withAppWrapper from '@/components/app/withAppWrapper';
import { DatabaseRow } from 'src/components/database/DatabaseRow';
import { DatabaseContextProvider } from 'src/components/database/DatabaseContext';
import * as Y from 'yjs';
import '@/components/layout/layout.scss';

describe('<DatabaseRow />', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    Object.defineProperty(window.navigator, 'languages', { value: ['en-US'] });
    cy.mockDatabase();
    cy.mockDocument('f56bdf0f-90c8-53fb-97d9-ad5860d2b7a0');
  });

  it('renders with a row', () => {
    cy.wait(1000);
    cy.fixture('folder').then((folderJson) => {
      const doc = new Y.Doc();
      const state = new Uint8Array(folderJson.data.doc_state);

      applyYDoc(doc, state);
      const folder = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.folder) as YFolder;

      cy.fixture('database/4c658817-20db-4f56-b7f9-0637a22dfeb6').then((database) => {
        const doc = new Y.Doc();
        const databaseState = new Uint8Array(database.data.doc_state);

        applyYDoc(doc, databaseState);

        cy.fixture('database/rows/4c658817-20db-4f56-b7f9-0637a22dfeb6').then((rows) => {
          const rootRowsDoc = new Y.Doc();
          const rowsFolder: Y.Map<YDoc> = rootRowsDoc.getMap();
          const data = rows['2f944220-9f45-40d9-96b5-e8c0888daf7c'];
          const rowDoc = new Y.Doc();

          applyYDoc(rowDoc, new Uint8Array(data));
          rowsFolder.set('2f944220-9f45-40d9-96b5-e8c0888daf7c', rowDoc);

          const AppWrapper = withAppWrapper(() => {
            return (
              <div className={'flex h-screen w-screen flex-col overflow-y-auto py-4'}>
                <TestDatabaseRow
                  rowId={'2f944220-9f45-40d9-96b5-e8c0888daf7c'}
                  databaseDoc={doc}
                  rows={rowsFolder}
                  folder={folder}
                  viewId={'7d2148fc-cace-4452-9c5c-96e52e6bf8b5'}
                />
              </div>
            );
          });

          cy.mount(<AppWrapper />);

          cy.wait(1000);

          cy.get('[role="textbox"]').should('exist');
        });
      });
    });
  });
});

function TestDatabaseRow({
  rowId,
  databaseDoc,
  rows,
  folder,
  viewId,
}: {
  rowId: string;
  databaseDoc: YDoc;
  rows: Y.Map<YDoc>;
  folder: YFolder;
  viewId: string;
}) {
  return (
    <FolderProvider folder={folder}>
      <IdProvider objectId={viewId}>
        <DatabaseContextProvider
          viewId={viewId}
          readOnly={true}
          isDatabaseRowPage
          databaseDoc={databaseDoc}
          rowDocMap={rows}
        >
          <DatabaseRow rowId={rowId} />
        </DatabaseContextProvider>
      </IdProvider>
    </FolderProvider>
  );
}
