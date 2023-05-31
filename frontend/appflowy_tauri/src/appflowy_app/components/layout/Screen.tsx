import React, { ReactNode, useEffect } from 'react';
import { NavigationPanel } from './NavigationPanel/NavigationPanel';
import { MainPanel } from './MainPanel';
import { useNavigationPanelHooks } from './NavigationPanel/NavigationPanel.hooks';
import { useWorkspace } from './Workspace.hooks';
import { useAppSelector } from '$app/stores/store';

export const Screen = ({ children }: { children: ReactNode }) => {
  const currentUser = useAppSelector((state) => state.currentUser);
  const { loadWorkspaceItems } = useWorkspace();
  useEffect(() => {
    void (async () => {
      await loadWorkspaceItems();
    })();
  }, [currentUser.isAuthenticated]);

  const { width, folders, pages, onPageClick, onHideMenuClick, onShowMenuClick, menuHidden } = useNavigationPanelHooks();

  return (
    <div className='flex h-screen w-screen bg-white text-black'>
      <NavigationPanel
        onHideMenuClick={onHideMenuClick}
        width={width}
        folders={folders}
        pages={pages}
        onPageClick={onPageClick}
        menuHidden={menuHidden}
      ></NavigationPanel>

      <MainPanel left={width} menuHidden={menuHidden} onShowMenuClick={onShowMenuClick}>
        {children}
      </MainPanel>
    </div>
  );
};
