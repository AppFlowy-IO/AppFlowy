import React, { ReactNode, useEffect } from 'react';
import { NavigationPanel } from './NavigationPanel/NavigationPanel';
import { MainPanel } from './MainPanel';
import { useNavigationPanelHooks } from './NavigationPanel/NavigationPanel.hooks';
import { NavigationFloatingPanel } from './NavigationPanel/NavigationFloatingPanel';
import { useWorkspace } from './Workspace.hooks';
import { useAppSelector } from '../../stores/store';

export const Screen = ({ children }: { children: ReactNode }) => {
  const currentUser = useAppSelector((state) => state.currentUser);
  const { loadWorkspaceItems } = useWorkspace();
  useEffect(() => {
    void (async () => {
      await loadWorkspaceItems();
    })();
  }, [currentUser.isAuthenticated]);

  const {
    width,
    folders,
    pages,
    onPageClick,
    onCollapseNavigationClick,
    onFixNavigationClick,
    navigationPanelFixed,
    onScreenMouseMove,
    slideInFloatingPanel,
    setFloatingPanelWidth,
    onHideMenuClick,
    onShowMenuClick,
    menuHidden,
  } = useNavigationPanelHooks();

  return (
    <div onMouseMove={onScreenMouseMove} className='flex h-screen w-screen bg-white text-black'>
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
