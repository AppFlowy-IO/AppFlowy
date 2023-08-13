import AddSvg from '../../_shared/svg/AddSvg';
import { CopySvg } from '../../_shared/svg/CopySvg';
import { TrashSvg } from '../../_shared/svg/TrashSvg';
import { ShareSvg } from '../../_shared/svg/ShareSvg';
import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { useGridRowActions } from './GridRowActions.hooks';
import { List, Popover } from '@mui/material';
import MenuItem from '@mui/material/MenuItem';
import React, { useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

export const GridRowActions = ({
  controller,
  rowId,
  isDragging,
  children,
}: {
  controller: DatabaseController;
  rowId: string;
  isDragging: boolean;
  children: React.ReactNode;
}) => {
  const { deleteRow, duplicateRow, insertRowAfter } = useGridRowActions(controller);
  const optionsButtonEl = useRef<HTMLButtonElement>(null);
  const [showMenu, setShowMenu] = useState(false);
  const { t } = useTranslation();

  return (
    <>
      <div className={'flex flex-shrink-0 items-center justify-center'}>
        <button
          ref={optionsButtonEl}
          onClick={() => setShowMenu(true)}
          className={`cursor-pointer items-center justify-center rounded p-1 opacity-0 hover:bg-fill-list-hover group-hover/row:opacity-100 ${
            isDragging || showMenu ? '!opacity-100' : ''
          }`}
        >
          {children}
        </button>
      </div>
      <Popover
        open={showMenu}
        anchorEl={optionsButtonEl.current}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'left',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        onClose={() => setShowMenu(false)}
      >
        <List>
          <MenuItem
            onClick={() => {
              void insertRowAfter(rowId);
              setShowMenu(false);
            }}
          >
            <span className={'mr-2'}>
              <i className={'block h-[16px] w-[16px]'}>
                <AddSvg />
              </i>
            </span>
            <span>{t('button.insertBelow')}</span>
          </MenuItem>
          <MenuItem onClick={() => console.log('copy link')}>
            <span className={'mr-2'}>
              <i className={'block h-[16px] w-[16px]'}>
                <ShareSvg />
              </i>
            </span>
            <span>{t('shareAction.copyLink')}</span>
          </MenuItem>
          <MenuItem
            onClick={() => {
              void duplicateRow(rowId);
              setShowMenu(false);
            }}
          >
            <span className={'mr-2'}>
              <i className={'block h-[16px] w-[16px]'}>
                <CopySvg />
              </i>
            </span>
            <span>{t('grid.row.duplicate')}</span>
          </MenuItem>
          <MenuItem
            onClick={() => {
              void deleteRow(rowId);
              setShowMenu(false);
            }}
          >
            <span className={'mr-2'}>
              <i className={'block h-[16px] w-[16px]'}>
                <TrashSvg />
              </i>
            </span>
            <span>{t('grid.row.delete')}</span>
          </MenuItem>
        </List>
      </Popover>
    </>
  );
};
