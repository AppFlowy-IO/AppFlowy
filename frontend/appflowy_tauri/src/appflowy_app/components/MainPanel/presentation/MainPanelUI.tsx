import { ReactNode } from 'react';
import { HeaderPanel } from '../../HeaderPanel/application/HeaderPanel';
import { FooterPanel } from '../../FooterPanel/application/FooterPanel';

export const MainPanelUI = ({ children }: { children: ReactNode }) => {
  return (
    <div className={'flex-1 h-full flex flex-col'}>
      <HeaderPanel></HeaderPanel>
      <div className={'flex-1 min-h-0 overflow-auto'}>{children}</div>
      <FooterPanel></FooterPanel>
    </div>
  );
};
