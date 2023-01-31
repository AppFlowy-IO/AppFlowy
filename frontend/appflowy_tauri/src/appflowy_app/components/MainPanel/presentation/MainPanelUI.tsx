import { ReactNode } from 'react';
import { HeaderPanel } from '../../HeaderPanel/application/HeaderPanel';

export const MainPanelUI = ({ children }: { children: ReactNode }) => {
  return (
    <div className={'flex-1 h-full flex flex-col'}>
      <HeaderPanel></HeaderPanel>
      <div className={'flex-1'}>{children}</div>
      <div>Footer</div>
    </div>
  );
};
