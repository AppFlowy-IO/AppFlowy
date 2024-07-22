import { YDoc } from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import withAppWrapper from '@/components/app/withAppWrapper';
import { DatabaseRow } from 'src/components/database/DatabaseRow';
import { DatabaseContextProvider } from 'src/components/database/DatabaseContext';
import * as Y from 'yjs';
import '@/styles/app.scss';

describe('<DatabaseRow />', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
  });

  it('renders with a row', () => {
    cy.wait(1000);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
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

        cy.fixture('simple_doc').then((docJson) => {
          const subDoc = new Y.Doc();
          const state = new Uint8Array(docJson.data.doc_state);

          applyYDoc(subDoc, state);
          const AppWrapper = withAppWrapper(() => {
            return (
              <div className={'flex h-screen w-screen flex-col overflow-y-auto py-4'}>
                <TestDatabaseRow
                  rowId={'2f944220-9f45-40d9-96b5-e8c0888daf7c'}
                  databaseDoc={doc}
                  rows={rowsFolder}
                  viewId={'7d2148fc-cace-4452-9c5c-96e52e6bf8b5'}
                  loadView={() => Promise.resolve(subDoc)}
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
  viewId,
  loadView,
}: {
  rowId: string;
  databaseDoc: YDoc;
  rows: Y.Map<YDoc>;
  viewId: string;
  loadView?: (viewId: string) => Promise<YDoc>;
}) {
  return (
    <DatabaseContextProvider
      iidIndex={viewId}
      viewId={viewId}
      readOnly={true}
      isDatabaseRowPage
      databaseDoc={databaseDoc}
      rowDocMap={rows}
      loadView={loadView}
    >
      <DatabaseRow rowId={rowId} />
    </DatabaseContextProvider>
  );
}
