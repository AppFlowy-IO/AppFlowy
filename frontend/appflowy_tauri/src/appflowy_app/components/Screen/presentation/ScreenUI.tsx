import React, { ReactNode } from 'react';
import { NavigationPanel } from '../../NavigationPanel/application/NavigationPanel';
import { MainPanel } from '../../MainPanel/application/MainPanel';

export const ScreenUI = ({ children }: { children: ReactNode }) => {
  return (
    <div className='bg-white text-black h-screen w-screen flex'>
      <NavigationPanel></NavigationPanel>
      <MainPanel>{children}</MainPanel>
    </div>
  );
};
