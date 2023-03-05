import { Workspace } from '../Workspace';
import { AppLogo } from '../AppLogo';
import { FolderItem } from './FolderItem';
import { PluginsButton } from './PluginsButton';
import { TrashButton } from './TrashButton';
import { NewFolderButton } from './NewFolderButton';
import { NavigationResizer } from './NavigationResizer';
import { IFolder } from '../../../stores/reducers/folders/slice';
import { IPage } from '../../../stores/reducers/pages/slice';

const MINIMUM_WIDTH = 200;
const ANIMATION_DURATION = 300;

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

          <Workspace></Workspace>

          <div className={'flex flex-col overflow-auto px-2'} style={{ height: 'calc(100vh - 280px)' }}>
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
      <NavigationResizer minWidth={MINIMUM_WIDTH}></NavigationResizer>
    </>
  );
};
