import { useParams } from 'react-router-dom';
import { ViewIdProvider } from '$app/hooks';
import { Database, DatabaseTitle, useSelectDatabaseView, VerticalScrollElementProvider } from '../components/database';
import { useRef } from 'react';

export const DatabasePage = () => {
  const viewId = useParams().id;

  const { selectedViewId, onChange } = useSelectDatabaseView();

  const ref = useRef<HTMLDivElement>(null);

  if (!viewId) {
    return null;
  }

  return (
    <div className='h-full overflow-y-auto px-16 caret-text-title' ref={ref}>
      <VerticalScrollElementProvider value={ref}>
        <ViewIdProvider value={viewId}>
          <DatabaseTitle />
          <Database selectedViewId={selectedViewId} setSelectedViewId={onChange} />
        </ViewIdProvider>
      </VerticalScrollElementProvider>
    </div>
  );
};
