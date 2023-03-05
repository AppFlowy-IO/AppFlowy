import { WorkspaceUser } from '../WorkspaceUser';
import { AppLogo } from '../AppLogo';
import { FolderItem } from './FolderItem';
import { TrashButton } from './TrashButton';
import { NewFolderButton } from './NewFolderButton';
import { NavigationResizer } from './NavigationResizer';
import { IFolder } from '../../../stores/reducers/folders/slice';
import { IPage } from '../../../stores/reducers/pages/slice';
import { useNavigate } from 'react-router-dom';
import React from 'react';

export const NavigationPanel = ({
  onCollapseNavigationClick,
  width,
  folders,
  pages,
  onPageClick,
}: {
  onCollapseNavigationClick: () => void;
  width: number;
  folders: IFolder[];
  pages: IPage[];
  onPageClick: (page: IPage) => void;
}) => {
  return (
    <>
      <div className={'flex flex-col justify-between bg-surface-1 text-sm'} style={{ width: `${width}px` }}>
        <div className={'flex flex-col'}>
          <AppLogo iconToShow={'hide'} onHideMenuClick={onCollapseNavigationClick}></AppLogo>
          <WorkspaceUser></WorkspaceUser>
          <WorkspaceApps folders={folders} pages={pages} onPageClick={onPageClick} />
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
      <NavigationResizer></NavigationResizer>
    </>
  );
};

type AppsContext = {
  folders: IFolder[];
  pages: IPage[];
  onPageClick: (page: IPage) => void;
};

const WorkspaceApps: React.FC<AppsContext> = ({ folders, pages, onPageClick }) => (
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
