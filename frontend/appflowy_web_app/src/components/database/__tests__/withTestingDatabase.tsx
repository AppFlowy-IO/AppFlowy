import { YDoc, YFolder, YjsEditorKey } from '@/application/collab.type';
import { applyYDoc } from '@/application/ydoc/apply';
import { FolderProvider } from '@/components/_shared/context-provider/FolderProvider';
import { IdProvider } from '@/components/_shared/context-provider/IdProvider';
import withAppWrapper from '@/components/app/withAppWrapper';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import { useState } from 'react';
import * as Y from 'yjs';
import { Database } from 'src/components/database/Database';

export function renderDatabase(
  {
    databaseId,
    viewId,
    onNavigateToView,
  }: {
    databaseId: string;
    viewId: string;
    onNavigateToView: (viewId: string) => void;
  },
  onAfterRender?: () => void
) {
  cy.fixture('folder').then((folderJson) => {
    const doc = new Y.Doc();
    const state = new Uint8Array(folderJson.data.doc_state);

    applyYDoc(doc, state);

    const folder = doc.getMap(YjsEditorKey.data_section).get(YjsEditorKey.folder) as YFolder;

    cy.fixture(`database/${databaseId}`).then((database) => {
      cy.fixture(`database/rows/${databaseId}`).then((rows) => {
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

        const AppWrapper = withAppWrapper(() => {
          return (
            <div className={'flex h-screen w-screen flex-col py-4'}>
              <TestDatabase
                databaseDoc={doc}
                rows={rowsFolder}
                folder={folder}
                iidIndex={viewId}
                initialViewId={viewId}
                onNavigateToView={onNavigateToView}
              />
            </div>
          );
        });

        cy.mount(<AppWrapper />);
        onAfterRender?.();
      });
    });
  });
}

export function TestDatabase({
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
