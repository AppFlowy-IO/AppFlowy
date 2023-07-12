import { Details2Svg } from '../../_shared/svg/Details2Svg';
import AddSvg from '../../_shared/svg/AddSvg';
import { IPage } from '$app_reducers/pages/slice';
import { useMemo, useRef } from 'react';
import { DropDownShowSvg } from '../../_shared/svg/DropDownShowSvg';
import { ANIMATION_DURATION } from '../../_shared/constants';
import { NavItemOptions, useNavItem } from '$app/components/layout/NavigationPanel/NavItem.hooks';
import { useAppSelector } from '$app/stores/store';
import { ViewLayoutPB } from '@/services/backend';
import Popover from '@mui/material/Popover';
import { IconButton, List } from '@mui/material';
import MoreMenu from '$app/components/layout/NavigationPanel/MoreMenu';
import NewPageMenu from '$app/components/layout/NavigationPanel/NewPageMenu';

export const NavItem = ({ page }: { page: IPage }) => {
  const pages = useAppSelector((state) => state.pages);
  const {
    onUnfoldClick,
    changePageTitle,
    deletePage,
    duplicatePage,

    onAddNewPage,

    activePageId,

    onPageClick,
    onClickMenuBtn,
    menuOpen,
    menuOption,
    setAnchorEl,
    selectedPage,
    anchorEl,
  } = useNavItem(page);

  const el = useRef<HTMLDivElement>(null);

  return (
    <>
      <div ref={el}>
        <div className={`transition-all`} style={{ transitionDuration: `${ANIMATION_DURATION}ms` }}>
          <div className={`cursor-pointer px-1 py-1`}>
            <div
              className={`flex items-center justify-between rounded-lg px-2 py-1 hover:bg-fill-list-hover ${
                activePageId === page.id ? 'bg-fill-list-hover' : ''
              }`}
            >
              <div className={'flex h-full min-w-0 flex-1 items-center'}>
                <button
                  onClick={() => onUnfoldClick()}
                  className={`mr-2 h-5 w-5 transition-transform duration-200 ${
                    page.showPagesInside ? 'rotate-180' : ''
                  }`}
                >
                  <DropDownShowSvg></DropDownShowSvg>
                </button>
                <div
                  onClick={() => onPageClick(page)}
                  className={'mr-1 flex h-full min-w-0 flex-1 items-center text-left'}
                >
                  <span className={'w-[100%] overflow-hidden overflow-ellipsis whitespace-nowrap'}>{page.title}</span>
                </div>
              </div>
              <div className={'flex items-center'}>
                <IconButton
                  className={'h-6 w-6'}
                  size={'small'}
                  onClick={(e) => {
                    setAnchorEl(e.currentTarget);
                    onClickMenuBtn(page, NavItemOptions.More);
                  }}
                >
                  <Details2Svg></Details2Svg>
                </IconButton>
                <IconButton
                  className={'h-6 w-6'}
                  size={'small'}
                  onClick={(e) => {
                    setAnchorEl(e.currentTarget);
                    onClickMenuBtn(page, NavItemOptions.NewPage);
                  }}
                >
                  <AddSvg></AddSvg>
                </IconButton>
              </div>
            </div>
          </div>
          <div className={`${page.showPagesInside ? '' : 'hidden'} pl-4`}>
            {useMemo(() => pages.filter((insidePage) => insidePage.parentPageId === page.id), [pages, page]).map(
              (insidePage, insideIndex) => (
                <NavItem key={insideIndex} page={insidePage}></NavItem>
              )
            )}
          </div>
        </div>
      </div>
      <Popover
        open={menuOpen}
        anchorEl={anchorEl}
        onClose={() => setAnchorEl(undefined)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'left' }}
        transformOrigin={{ vertical: 'top', horizontal: 'left' }}
      >
        <List>
          {menuOption === NavItemOptions.More && selectedPage && (
            <MoreMenu
              selectedPage={selectedPage}
              onRename={changePageTitle}
              onDeleteClick={() => deletePage()}
              onDuplicateClick={() => duplicatePage()}
            />
          )}
          {menuOption === NavItemOptions.NewPage && (
            <NewPageMenu
              onDocumentClick={() => onAddNewPage(ViewLayoutPB.Document)}
              onBoardClick={() => onAddNewPage(ViewLayoutPB.Board)}
              onGridClick={() => onAddNewPage(ViewLayoutPB.Grid)}
            />
          )}
        </List>
      </Popover>
    </>
  );
};
