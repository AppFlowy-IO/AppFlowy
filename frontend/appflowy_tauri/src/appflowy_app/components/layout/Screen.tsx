import React, { ReactNode } from 'react';
import { NavigationPanel } from './NavigationPanel/NavigationPanel';
import { MainPanel } from './MainPanel';

export const Screen = ({ children }: { children: ReactNode }) => {
  return (
    <div className='bg-white text-black h-screen w-screen flex'>
      <NavigationPanel></NavigationPanel>
      <MainPanel>{children}</MainPanel>
    </div>
  );
};
