import { Details2Svg } from '../../_shared/svg/Details2Svg';
import AddSvg from '../../_shared/svg/AddSvg';
import { NavItemOptionsPopup } from './NavItemOptionsPopup';
import { NewPagePopup } from './NewPagePopup';
import { IPage } from '$app_reducers/pages/slice';
import { Button } from '../../_shared/Button';
import { RenamePopup } from './RenamePopup';
import { useEffect, useRef, useState } from 'react';
import { DropDownShowSvg } from '../../_shared/svg/DropDownShowSvg';
import { ANIMATION_DURATION, PAGE_ITEM_HEIGHT } from '../../_shared/constants';
import { useNavItem } from '$app/components/layout/NavigationPanel/NavItem.hooks';
import { useAppSelector } from '$app/stores/store';

export const NavItemWrapper = ({ page }: { page: IPage }) => {
  const pages = useAppSelector((state) => state.pages);
  const {
    onUnfoldClick,
    onNewPageClick,
    onPageOptionsClick,
    startPageRename,

    changePageTitle,
    closeRenamePopup,
    closePopup,

    showNewPageOptions,
    showPageOptions,
    showRenamePopup,

    deletePage,
    duplicatePage,

    onAddNewDocumentPage,
    onAddNewBoardPage,
    onAddNewGridPage,

    folderHeight,
    activePageId,

    onPageClick,
  } = useNavItem(page);

  const [popupY, setPopupY] = useState(0);

  const el = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (el.current) {
      const { top } = el.current.getBoundingClientRect();
      setPopupY(top);
    }
  }, [showPageOptions, showNewPageOptions, showRenamePopup]);

  return (
    <div ref={el}>
      <div
        className={`overflow-hidden transition-all`}
        style={{ height: folderHeight, transitionDuration: `${ANIMATION_DURATION}ms` }}
      >
        <div
          style={{ height: PAGE_ITEM_HEIGHT }}
          className={'flex cursor-pointer items-center justify-between rounded-lg px-4 hover:bg-surface-2'}
        >
          <button className={'flex min-w-0 flex-1 items-center'}>
            <i
              onClick={() => onUnfoldClick()}
              className={`mr-2 h-5 w-5 transition-transform duration-200 ${page.showPagesInside && 'rotate-180'}`}
            >
              <DropDownShowSvg></DropDownShowSvg>
            </i>
            <span
              onClick={() => onPageClick(page)}
              className={'min-w-0 flex-1 overflow-hidden overflow-ellipsis whitespace-nowrap text-left'}
            >
              {page.title}
            </span>
          </button>
          <div className={'flex items-center'}>
            <Button size={'box-small-transparent'} onClick={() => onPageOptionsClick()}>
              <Details2Svg></Details2Svg>
            </Button>
            <Button size={'box-small-transparent'} onClick={() => onNewPageClick()}>
              <AddSvg></AddSvg>
            </Button>
          </div>
        </div>
        <div className={'pl-4'}>
          {pages
            .filter((insidePage) => insidePage.parentPageId === page.id)
            .map((insidePage, index) => (
              <NavItemWrapper key={index} page={insidePage}></NavItemWrapper>
            ))}
        </div>
      </div>
      {showPageOptions && (
        <NavItemOptionsPopup
          onRenameClick={() => startPageRename()}
          onDeleteClick={() => deletePage()}
          onDuplicateClick={() => duplicatePage()}
          onClose={() => closePopup()}
          top={popupY - 124 + 40}
        ></NavItemOptionsPopup>
      )}
      {showNewPageOptions && (
        <NewPagePopup
          onDocumentClick={() => onAddNewDocumentPage()}
          onBoardClick={() => onAddNewBoardPage()}
          onGridClick={() => onAddNewGridPage()}
          onClose={() => closePopup()}
          top={popupY - 124 + 40}
        ></NewPagePopup>
      )}
      {showRenamePopup && (
        <RenamePopup
          value={page.title}
          onChange={(newTitle) => changePageTitle(newTitle)}
          onClose={closeRenamePopup}
          top={popupY - 124 + 40}
        ></RenamePopup>
      )}
    </div>
  );
};
