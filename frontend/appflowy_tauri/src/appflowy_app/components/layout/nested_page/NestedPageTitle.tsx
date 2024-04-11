import React, { useMemo, useState } from 'react';
import { useAppSelector } from '$app/stores/store';
import AddButton from './AddButton';
import MoreButton from './MoreButton';
import { ViewLayoutPB } from '@/services/backend';
import { useSelectedPage } from '$app/components/layout/nested_page/NestedPage.hooks';
import { useTranslation } from 'react-i18next';
import { ReactComponent as MoreIcon } from '$app/assets/more.svg';
import { IconButton } from '@mui/material';
import { Page } from '$app_reducers/pages/slice';
import { getPageIcon } from '$app/hooks/page.hooks';

function NestedPageTitle({
  pageId,
  collapsed,
  toggleCollapsed,
  onAddPage,
  onClick,
  onDelete,
  onDuplicate,
  onRename,
}: {
  pageId: string;
  collapsed: boolean;
  toggleCollapsed: () => void;
  onAddPage: (layout: ViewLayoutPB) => void;
  onClick: () => void;
  onDelete: () => Promise<void>;
  onDuplicate: () => Promise<void>;
  onRename: (newName: string) => Promise<void>;
}) {
  const { t } = useTranslation();
  const page = useAppSelector((state) => {
    return state.pages.pageMap[pageId] as Page | undefined;
  });
  const disableChildren = useAppSelector((state) => {
    if (!page) return true;
    const layout = state.pages.pageMap[page.parentId]?.layout;

    return !(layout === undefined || layout === ViewLayoutPB.Document);
  });

  const [isHovering, setIsHovering] = useState(false);
  const isSelected = useSelectedPage(pageId);

  const pageIcon = useMemo(() => (page ? getPageIcon(page) : null), [page]);

  return (
    <div
      className={`my-0.5 cursor-pointer rounded-lg bg-opacity-40 p-0.5  ${isHovering ? 'bg-fill-list-hover' : ''} ${
        isSelected ? 'bg-fill-list-active' : ''
      }`}
      onClick={onClick}
      onMouseMove={() => setIsHovering(true)}
      onMouseLeave={() => setIsHovering(false)}
    >
      <div className={'flex h-6 w-[100%] items-center justify-between'}>
        <div className={'flex flex-1 items-center justify-start gap-1 overflow-hidden'}>
          {disableChildren ? (
            <div className={'mx-2 h-1 w-1 rounded-full bg-text-title'} />
          ) : (
            <IconButton
              size={'small'}
              onClick={(e) => {
                e.stopPropagation();
                toggleCollapsed();
              }}
              style={{
                transform: collapsed ? 'rotate(0deg)' : 'rotate(90deg)',
              }}
            >
              <MoreIcon className={'h-4 w-4 text-text-title'} />
            </IconButton>
          )}

          {pageIcon}

          <div className={'flex-1 overflow-hidden text-ellipsis whitespace-nowrap'}>
            {page?.name.trim() || t('menuAppHeader.defaultNewPageName')}
          </div>
        </div>
        <div onClick={(e) => e.stopPropagation()} className={'min:w-14 flex items-center justify-end px-2'}>
          {page?.layout === ViewLayoutPB.Document && (
            <AddButton setHovering={setIsHovering} isHovering={isHovering} onAddPage={onAddPage} />
          )}
          {page && (
            <MoreButton
              setHovering={setIsHovering}
              isHovering={isHovering}
              page={page}
              onDelete={onDelete}
              onDuplicate={onDuplicate}
              onRename={onRename}
            />
          )}
        </div>
      </div>
    </div>
  );
}

export default NestedPageTitle;
