import React, { ReactNode } from 'react';
import { NavigationPanel } from './NavigationPanel/NavigationPanel';
import { MainPanel } from './MainPanel';

export const Screen = ({ children }: { children: ReactNode }) => {
  return (
    <div className='flex h-screen w-screen bg-white text-black'>
      <NavigationPanel></NavigationPanel>
      <MainPanel>{children}</MainPanel>
    </div>
  );
};
