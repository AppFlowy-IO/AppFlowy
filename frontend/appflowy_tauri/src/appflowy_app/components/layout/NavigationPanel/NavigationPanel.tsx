import { WorkspaceUser } from '../WorkspaceUser';
import { AppLogo } from '../AppLogo';
import { TrashButton } from './TrashButton';
import { NewViewButton } from './NewViewButton';
import { NavigationResizer } from './NavigationResizer';
import { IPage } from '$app_reducers/pages/slice';
import { useLocation, useNavigate } from 'react-router-dom';
import React, { useEffect, useRef, useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import { NavItem } from '$app/components/layout/NavigationPanel/NavItem';
import { ANIMATION_DURATION, NAV_PANEL_MINIMUM_WIDTH, PAGE_ITEM_HEIGHT } from '../../_shared/constants';

export const NavigationPanel = ({
  onHideMenuClick,
  menuHidden,
  width,
}: {
  onHideMenuClick: () => void;
  menuHidden: boolean;
  width: number;
}) => {
  const el = useRef<HTMLDivElement>(null);
  const pages = useAppSelector((state) => state.pages);
  const workspace = useAppSelector((state) => state.workspace);
  const [activePageId, setActivePageId] = useState<string>('');
  const currentLocation = useLocation();
  const [maxHeight, setMaxHeight] = useState(0);

  useEffect(() => {
    const { pathname } = currentLocation;
    const parts = pathname.split('/');
    const pageId = parts[parts.length - 1];

    setActivePageId(pageId);
  }, [currentLocation]);

  useEffect(() => {
    setMaxHeight(pages.length * PAGE_ITEM_HEIGHT);
  }, [pages]);

  const scrollDown = () => {
    setTimeout(() => {
      el?.current?.scrollTo({ top: maxHeight, behavior: 'smooth' });
    }, ANIMATION_DURATION);
  };

  return (
    <>
      <div
        className={`absolute inset-0 flex flex-col justify-between bg-bg-base text-sm text-text-title`}
        style={{
          transition: `left ${ANIMATION_DURATION}ms ease-out`,
          width: `${width}px`,
          left: `${menuHidden ? -width : 0}px`,
        }}
      >
        <AppLogo iconToShow={'hide'} onHideMenuClick={onHideMenuClick}></AppLogo>
        <WorkspaceUser></WorkspaceUser>
        <div className={'relative flex flex-1 flex-col'}>
          <div className={'flex h-[100%] flex-col overflow-auto px-2'} ref={el}>
            <WorkspaceApps pages={pages.filter((p) => p.parentPageId === workspace.id)} />
          </div>
        </div>

        <div className={'flex max-h-[240px] flex-col'}>
          <div className={'border-b border-line-divider px-2 pb-4'}>
            {/*<PluginsButton></PluginsButton>*/}

            {/*<DesignSpec></DesignSpec>*/}
            {/*<AllIcons></AllIcons>*/}
            {/*<TestBackendButton></TestBackendButton>*/}

            {/*Trash Button*/}
            <TrashButton></TrashButton>
          </div>

          {/*New Root View Button*/}
          <NewViewButton scrollDown={scrollDown}></NewViewButton>
        </div>
      </div>
      <NavigationResizer minWidth={NAV_PANEL_MINIMUM_WIDTH}></NavigationResizer>
    </>
  );
};

const WorkspaceApps: React.FC<{ pages: IPage[] }> = ({ pages }) => (
  <>
    {pages.map((page, index) => (
      <NavItem key={index} page={page}></NavItem>
    ))}
  </>
);

export const TestBackendButton = () => {
  const navigate = useNavigate();

  return (
    <button
      onClick={() => navigate('/page/api-test')}
      className={'hover:bg-fill-active flex w-full items-center rounded-lg px-4 py-2'}
    >
      API Test
    </button>
  );
};

export const DesignSpec = () => {
  const navigate = useNavigate();

  return (
    <button
      onClick={() => navigate('page/colors')}
      className={'hover:bg-fill-active flex w-full items-center rounded-lg px-4 py-2'}
    >
      Color Palette
    </button>
  );
};

export const AllIcons = () => {
  const navigate = useNavigate();

  return (
    <button
      onClick={() => navigate('page/all-icons')}
      className={'hover:bg-fill-active flex w-full items-center rounded-lg px-4 py-2'}
    >
      All Icons
    </button>
  );
};
