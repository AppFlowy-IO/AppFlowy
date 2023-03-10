import { AppLogo } from '../AppLogo';
import { WorkspaceUser } from '../WorkspaceUser';
import { FolderItem } from './FolderItem';
import { PluginsButton } from './PluginsButton';
import { TrashButton } from './TrashButton';
import { NewFolderButton } from './NewFolderButton';
import { IFolder } from '../../../stores/reducers/folders/slice';
import { IPage } from '../../../stores/reducers/pages/slice';
import { useEffect, useRef, useState } from 'react';

const animationDuration = 500;

export const NavigationFloatingPanel = ({
  onFixNavigationClick,
  slideInFloatingPanel,
  folders,
  pages,
  onPageClick,
  setWidth,
}: {
  onFixNavigationClick: () => void;
  slideInFloatingPanel: boolean;
  folders: IFolder[];
  pages: IPage[];
  onPageClick: (page: IPage) => void;
  setWidth: (v: number) => void;
}) => {
  const el = useRef<HTMLDivElement>(null);
  const [panelLeft, setPanelLeft] = useState(0);

  useEffect(() => {
    if (!el?.current) return;

    const { width } = el.current.getBoundingClientRect();
    setWidth(width);

    if (slideInFloatingPanel) {
      setPanelLeft(0);
    } else {
      setPanelLeft(-width);
    }
  }, [el.current, slideInFloatingPanel]);

  return (
    <div
      ref={el}
      className={
        'fixed top-16 z-10 flex flex-col justify-between rounded-tr rounded-br border border-l-0 border-shade-4 bg-white text-sm shadow-md transition-all'
      }
      style={{ left: panelLeft, transitionDuration: `${animationDuration}ms` }}
    >
      <div className={'flex flex-col'}>
        <AppLogo iconToShow={'show'} onShowMenuClick={onFixNavigationClick}></AppLogo>

        <WorkspaceUser></WorkspaceUser>

        <div className={'flex flex-col px-2'}>
          {folders.map((folder, index) => (
            <FolderItem
              key={index}
              folder={folder}
              pages={pages.filter((page) => page.folderId === folder.id)}
              onPageClick={onPageClick}
            ></FolderItem>
          ))}
        </div>
      </div>

      <div className={'flex flex-col'}>
        <div className={'border-b border-shade-6 px-2 pb-4'}>
          <PluginsButton></PluginsButton>
          <TrashButton></TrashButton>
        </div>

        <NewFolderButton></NewFolderButton>
      </div>
    </div>
  );
};
