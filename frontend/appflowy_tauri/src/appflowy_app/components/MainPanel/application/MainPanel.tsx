import { ReactNode } from 'react';
import { MainPanelUI } from '../presentation/MainPanelUI';

export const MainPanel = ({ children }: { children: ReactNode }) => {
  return <MainPanelUI>{children}</MainPanelUI>;
};
