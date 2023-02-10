import { ReactNode } from 'react';
import { HeaderPanel } from './HeaderPanel/HeaderPanel';
import { FooterPanel } from './FooterPanel';

export const MainPanel = ({ children }: { children: ReactNode }) => {
  return (
    <div className={'flex h-full flex-1 flex-col'}>
      <HeaderPanel></HeaderPanel>
      <div className={'min-h-0 flex-1 overflow-auto'}>{children}</div>
      <FooterPanel></FooterPanel>
    </div>
  );
};
