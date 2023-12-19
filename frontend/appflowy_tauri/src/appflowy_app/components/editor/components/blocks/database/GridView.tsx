import React, { useState } from 'react';
import { Database } from '$app/components/database';
import { ViewIdProvider } from '$app/hooks';

function GridView({ viewId }: { viewId: string }) {
  const [selectedViewId, onChangeSelectedViewId] = useState(viewId);

  return (
    <ViewIdProvider value={viewId}>
      <Database selectedViewId={selectedViewId} setSelectedViewId={onChangeSelectedViewId} />
    </ViewIdProvider>
  );
}

export default React.memo(GridView);
