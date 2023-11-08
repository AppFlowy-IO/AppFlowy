import { FC, PropsWithChildren } from 'react';
import { ViewIdProvider } from '$app/hooks';
import { DatabaseProvider, useConnectDatabase } from './Database.hooks';

export interface DatabaseLoaderProps {
  viewId: string;
}

export const DatabaseLoader: FC<PropsWithChildren<DatabaseLoaderProps>> = ({ viewId, children }) => {
  const database = useConnectDatabase(viewId);

  return (
    <DatabaseProvider value={database}>
      {/* Make sure that the viewId is current */}
      <ViewIdProvider value={viewId}>{children}</ViewIdProvider>
    </DatabaseProvider>
  );
};
