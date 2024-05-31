import { YDoc, YFolder, YjsEditorKey } from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import { FolderProvider } from '@/components/_shared/context-provider/FolderProvider';
import { IdProvider } from '@/components/_shared/context-provider/IdProvider';
import withAppWrapper from '@/components/app/withAppWrapper';
import { useState } from 'react';
import { Database } from './Database';
import { DatabaseContextProvider } from './DatabaseContext';
import * as Y from 'yjs';
import '@/components/layout/layout.scss';

describe('<Database />', () => {
  beforeEach(() => {
    cy.viewport(1280, 720);
    Object.defineProperty(window.navigator, 'language', { value: 'en-US' });
    Object.defineProperty(window.navigator, 'languages', { value: ['en-US'] });
    cy.mockDatabase();
  });

  it('renders with a database', () => {
    cy.fixture('folder').then((folderJson) => {
      const doc = new Y.Doc();
      const state = new Uint8Array(folderJson.data.doc_state);
      applyYDoc(doc, state);
      const folder = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.folder) as YFolder;

      cy.fixture(`database/4c658817-20db-4f56-b7f9-0637a22dfeb6`).then((database) => {
        cy.fixture(`database/rows/4c658817-20db-4f56-b7f9-0637a22dfeb6`).then((rows) => {
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

          const onNavigateToView = cy.stub();

          const AppWrapper = withAppWrapper(() => {
            return (
              <div className={'flex h-screen w-screen flex-col py-4'}>
                <TestDatabase
                  databaseDoc={doc}
                  rows={rowsFolder}
                  folder={folder}
                  iidIndex={'7d2148fc-cace-4452-9c5c-96e52e6bf8b5'}
                  initialViewId={'7d2148fc-cace-4452-9c5c-96e52e6bf8b5'}
                  onNavigateToView={onNavigateToView}
                />
              </div>
            );
          });

          cy.mount(<AppWrapper />);

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
        });
      });
    });
  });
});

function TestDatabase({
  databaseDoc,
  rows,
  folder,
  iidIndex,
  initialViewId,
  onNavigateToView,
}: {
  databaseDoc: YDoc;
  rows: Y.Map<YDoc>;
  folder: YFolder;
  iidIndex: string;
  initialViewId: string;
  onNavigateToView: (viewId: string) => void;
}) {
  const [activeViewId, setActiveViewId] = useState<string>(initialViewId);

  const handleNavigateToView = (viewId: string) => {
    setActiveViewId(viewId);
    onNavigateToView(viewId);
  };

  return (
    <FolderProvider folder={folder}>
      <IdProvider objectId={iidIndex}>
        <DatabaseContextProvider
          viewId={activeViewId || iidIndex}
          databaseDoc={databaseDoc}
          rowDocMap={rows}
          readOnly={true}
        >
          <Database iidIndex={iidIndex} viewId={activeViewId} onNavigateToView={handleNavigateToView} />
        </DatabaseContextProvider>
      </IdProvider>
    </FolderProvider>
  );
}
