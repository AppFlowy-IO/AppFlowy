import { RowId, YDoc } from '@/application/types';
import { applyYDoc } from '@/application/ydoc/apply';
import withAppWrapper from '@/components/main/withAppWrapper';
import { DatabaseContextProvider } from '@/components/database/DatabaseContext';
import DatabaseViews from '@/components/database/DatabaseViews';
import { useState } from 'react';
import * as Y from 'yjs';

export function renderDatabase (
  {
    databaseId,
    viewId,
    onNavigateToView,
  }: {
    databaseId: string;
    viewId: string;
    onNavigateToView: (viewId: string) => void;
  },
  onAfterRender?: () => void,
) {
  cy.fixture(`database/${databaseId}`).then((database) => {
    cy.fixture(`database/rows/${databaseId}`).then((rows) => {
      const doc = new Y.Doc();
      const rowsFolder: Record<RowId, YDoc> = {};
      const databaseState = new Uint8Array(database.data.doc_state);

      applyYDoc(doc, databaseState);

      Object.keys(rows).forEach((key) => {
        const data = rows[key];
        const rowDoc = new Y.Doc();

        applyYDoc(rowDoc, new Uint8Array(data));
        rowsFolder[key] = rowDoc;
      });

      const AppWrapper = withAppWrapper(() => {
        return (
          <div className={'flex h-screen w-screen flex-col py-4'}>
            <TestDatabase
              databaseDoc={doc}
              rows={rowsFolder}
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
}

export function TestDatabase ({
  databaseDoc,
  rows,
  iidIndex,
  initialViewId,
  onNavigateToView,
}: {
  databaseDoc: YDoc;
  rows: Record<RowId, YDoc>;
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
    <DatabaseContextProvider
      viewId={activeViewId || iidIndex}
      databaseDoc={databaseDoc}
      rowDocMap={rows}
      readOnly={true}
      iidIndex={iidIndex}
    >
      <DatabaseViews iidIndex={iidIndex} viewId={activeViewId} onChangeView={handleNavigateToView} />
    </DatabaseContextProvider>
  );
}
