import { useParams } from 'react-router-dom';
import { ViewIdProvider } from '$app/hooks';
import { Database, DatabaseTitle, useSelectDatabaseView } from '../components/database';

export const DatabasePage = () => {
  const viewId = useParams().id;

  const { selectedViewId, onChange } = useSelectDatabaseView({
    viewId,
  });

  if (!viewId) {
    return null;
  }

  return (
    <div className="flex h-full w-full flex-col overflow-hidden caret-text-title">
      <ViewIdProvider value={viewId}>
        <DatabaseTitle/>
        <Database selectedViewId={selectedViewId} setSelectedViewId={onChange}/>
      </ViewIdProvider>
    </div>
  );
};
