import { DatabaseContext, DatabaseContextState } from '@/application/database-yjs';

export const DatabaseContextProvider = ({
  children,
  ...props
}: DatabaseContextState & {
  children: React.ReactNode;
}) => {
  return <DatabaseContext.Provider value={props}>{children}</DatabaseContext.Provider>;
};
