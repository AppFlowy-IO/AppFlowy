import { WorkspaceUser } from '../WorkspaceUser';
import { AppLogo } from '../AppLogo';
import { FolderItem } from './FolderItem';
import { TrashButton } from './TrashButton';
import { NewFolderButton } from './NewFolderButton';
import { NavigationResizer } from './NavigationResizer';
import { IFolder } from '../../../stores/reducers/folders/slice';
import { IPage } from '../../../stores/reducers/pages/slice';
import { useNavigate } from 'react-router-dom';
import React, { useRef } from 'react';
import { useDispatch } from 'react-redux';
import { useAppSelector } from '../../../stores/store';
import { ANIMATION_DURATION, NAV_PANEL_MINIMUM_WIDTH } from '../../_shared/constants';

export const NavigationPanel = ({
  onHideMenuClick,
  menuHidden,
  width,
  folders,
  pages,
  onPageClick,
}: {
  onHideMenuClick: () => void;
  menuHidden: boolean;
  width: number;
  folders: IFolder[];
  pages: IPage[];
  onPageClick: (page: IPage) => void;
}) => {
  const el = useRef<HTMLDivElement>(null);
  const dispatch = useDispatch();
  const foldersStore = useAppSelector((state) => state.folders);
  const pagesStore = useAppSelector((state) => state.pages);
  const activePageId = useAppSelector((state) => state.activePageId);

  return (
    <>
      <div
        className={`absolute inset-0 flex flex-col justify-between bg-surface-1 text-sm`}
        style={{
          transition: `left ${ANIMATION_DURATION}ms ease-out`,
          width: `${width}px`,
          left: `${menuHidden ? -width : 0}px`,
        }}
      >
        <div className={'flex flex-col'}>
          <AppLogo iconToShow={'hide'} onHideMenuClick={onHideMenuClick}></AppLogo>
          <WorkspaceUser></WorkspaceUser>
          <div className={'relative flex flex-col'} style={{ height: 'calc(100vh - 300px)' }} ref={el}>
            <div className={'flex flex-col overflow-auto px-2'}>
              <WorkspaceApps folders={folders} pages={pages} onPageClick={onPageClick} />
            </div>
          </div>
        </div>

        <div className={'flex flex-col'}>
          <div className={'border-b border-shade-6 px-2 pb-4'}>
            {/*<PluginsButton></PluginsButton>*/}

            <DesignSpec></DesignSpec>
            <TestBackendButton></TestBackendButton>

            {/*Trash Button*/}
            <TrashButton></TrashButton>
          </div>

          {/*New Folder Button*/}
          <NewFolderButton></NewFolderButton>
        </div>
      </div>
      <NavigationResizer minWidth={NAV_PANEL_MINIMUM_WIDTH}></NavigationResizer>
    </>
  );
};

type AppsContext = {
  folders: IFolder[];
  pages: IPage[];
  onPageClick: (page: IPage) => void;
};

const WorkspaceApps: React.FC<AppsContext> = ({ folders, pages, onPageClick }) => (
  <>
    {folders.map((folder, index) => (
      <FolderItem
        key={index}
        folder={folder}
        pages={pages.filter((page) => page.folderId === folder.id)}
        onPageClick={onPageClick}
      ></FolderItem>
    ))}
  </>
);

export const TestBackendButton = () => {
  const navigate = useNavigate();
  return (
    <button
      onClick={() => navigate('/page/api-test')}
      className={'flex w-full items-center rounded-lg px-4 py-2 hover:bg-surface-2'}
    >
      APITest
    </button>
  );
};

export const DesignSpec = () => {
  const navigate = useNavigate();

  return (
    <button
      onClick={() => navigate('page/colors')}
      className={'flex w-full items-center rounded-lg px-4 py-2 hover:bg-surface-2'}
    >
      Design Specs
    </button>
  );
};
