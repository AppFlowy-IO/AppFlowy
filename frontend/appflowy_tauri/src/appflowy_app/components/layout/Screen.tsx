import React, { ReactNode } from 'react';
import { NavigationPanel } from './NavigationPanel/NavigationPanel';
import { MainPanel } from './MainPanel';
import { useNavigationPanelHooks } from './NavigationPanel/NavigationPanel.hooks';
import { useWorkspace } from './Workspace.hooks';

export const Screen = ({ children }: { children: ReactNode }) => {
  useWorkspace();

  const { width, onHideMenuClick, onShowMenuClick, menuHidden } = useNavigationPanelHooks();

  return (
    <div className='flex h-screen w-screen bg-white text-black'>
      <NavigationPanel onHideMenuClick={onHideMenuClick} width={width} menuHidden={menuHidden}></NavigationPanel>

      <MainPanel left={width} menuHidden={menuHidden} onShowMenuClick={onShowMenuClick}>
        {children}
      </MainPanel>
    </div>
  );
};
