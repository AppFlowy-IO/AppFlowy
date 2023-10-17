import { FC, PropsWithChildren } from 'react';
import { ViewIdProvider } from '$app/hooks';
import { DatabaseProvider, useConnectDatabase } from './Database.hooks';

export interface DatabaseLoaderProps {
  viewId: string
}

export const DatabaseLoader: FC<PropsWithChildren<DatabaseLoaderProps>> = ({
  viewId,
  children,
}) => {
  const database = useConnectDatabase(viewId);

  return (
    <DatabaseProvider value={database}>
      <ViewIdProvider value={viewId}>
        {children}
      </ViewIdProvider>
    </DatabaseProvider>
  );
};
