import React, { useState } from 'react';
import { ArrowRightSvg } from '$app/components/_shared/svg/ArrowRightSvg';
import MenuItem from '@mui/material/MenuItem';
import { useAppSelector } from '$app/stores/store';
import AddButton from './AddButton';
import MoreButton from './MoreButton';
import { ViewLayoutPB } from '@/services/backend';
import { useSelectedPage } from '$app/components/layout/NestedPage/NestedPage.hooks';

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
  const page = useAppSelector((state) => {
    return state.pages.map[pageId];
  });
  const [isHovering, setIsHovering] = useState(false);
  const isSelected = useSelectedPage(pageId);

  return (
    <MenuItem
      selected={isSelected}
      onClick={onClick}
      onMouseEnter={() => setIsHovering(true)}
      onMouseLeave={() => setIsHovering(false)}
    >
      <div className={'flex h-6 w-[100%] items-center justify-between'}>
        <div className={'flex flex-1 items-center justify-start overflow-hidden'}>
          <button
            onClick={(e) => {
              e.stopPropagation();
              toggleCollapsed();
            }}
            style={{
              transform: collapsed ? 'rotate(0deg)' : 'rotate(-90deg)',
            }}
            className={'flex h-[100%] w-8 items-center justify-center p-2'}
          >
            <div className={'h-5 w-5'}>
              <ArrowRightSvg />
            </div>
          </button>
          <div className={'flex-1 overflow-hidden text-ellipsis whitespace-nowrap'}>{page.name}</div>
        </div>
        <div onClick={(e) => e.stopPropagation()} className={'min:w-14 flex items-center justify-end'}>
          <AddButton isVisible={isHovering} onAddPage={onAddPage} />
          <MoreButton
            page={page}
            isVisible={isHovering}
            onDelete={onDelete}
            onDuplicate={onDuplicate}
            onRename={onRename}
          />
        </div>
      </div>
    </MenuItem>
  );
}

export default NestedPageTitle;
