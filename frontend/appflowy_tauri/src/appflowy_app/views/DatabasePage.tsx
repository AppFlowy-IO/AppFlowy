import { useParams } from 'react-router-dom';
import { ViewIdProvider } from '$app/hooks';
import { Database, DatabaseTitle, VerticalScrollElementProvider } from '../components/database';
import { useRef } from 'react';

export const DatabasePage = () => {
  const viewId = useParams().id;

  const ref = useRef<HTMLDivElement>(null);

  if (!viewId) {
    return null;
  }

  return (
    <div className="h-full overflow-y-auto" ref={ref}>
      <VerticalScrollElementProvider value={ref}>
        <ViewIdProvider value={viewId}>
          <DatabaseTitle />
          <Database />
        </ViewIdProvider>
      </VerticalScrollElementProvider>
    </div>
  );
};
