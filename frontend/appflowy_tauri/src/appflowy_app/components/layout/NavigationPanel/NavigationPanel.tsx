import { Workspace } from '../Workspace';
import { AppLogo } from '../AppLogo';
import { FolderItem } from './FolderItem';
import { PluginsButton } from './PluginsButton';
import { TrashButton } from './TrashButton';
import { NewFolderButton } from './NewFolderButton';
import { NavigationResizer } from './NavigationResizer';
import { IFolder } from '../../../stores/reducers/folders/slice';
import { IPage } from '../../../stores/reducers/pages/slice';

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
      f
      <div className={'flex flex-col justify-between bg-surface-1 text-sm'} style={{ width: `${width}px` }}>
        <div className={'flex flex-col'}>
          <AppLogo iconToShow={'hide'} onHideMenuClick={onCollapseNavigationClick}></AppLogo>
          <Workspace></Workspace>
          <FolderItems folders={folders} pages={pages} onPageClick={onPageClick} />
        </div>

        <div className={'flex flex-col'}>
          <div className={'border-b border-shade-6 px-2 pb-4'}>
            <PluginsButton></PluginsButton>
            <TrashButton></TrashButton>
          </div>

          <NewFolderButton></NewFolderButton>
        </div>
      </div>
      <NavigationResizer></NavigationResizer>
    </>
  );
};

type FolderItemsContext = {
  folders: IFolder[];
  pages: IPage[];
  onPageClick: (page: IPage) => void;
};

const FolderItems: React.FC<FolderItemsContext> = ({ folders, pages, onPageClick }) => (
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
