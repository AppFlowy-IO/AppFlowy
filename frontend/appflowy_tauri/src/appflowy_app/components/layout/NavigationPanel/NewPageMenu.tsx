import React, { useMemo } from 'react';
import { DocumentSvg } from '$app/components/_shared/svg/DocumentSvg';
import { BoardSvg } from '$app/components/_shared/svg/BoardSvg';
import { GridSvg } from '$app/components/_shared/svg/GridSvg';
import MenuItem from '@mui/material/MenuItem';
import { useTranslation } from 'react-i18next';

function NewPageMenu({
  onDocumentClick,
  onGridClick,
  onBoardClick,
}: {
  onDocumentClick: () => void;
  onGridClick: () => void;
  onBoardClick: () => void;
}) {
  const { t } = useTranslation();
  const items = useMemo(
    () => [
      {
        icon: (
          <i className={'h-[16px] w-[16px] text-text-title'}>
            <DocumentSvg></DocumentSvg>
          </i>
        ),
        onClick: onDocumentClick,
        title: t('document.menuName'),
      },
      {
        icon: (
          <i className={'h-[16px] w-[16px] text-text-title'}>
            <BoardSvg></BoardSvg>
          </i>
        ),
        onClick: onBoardClick,
        title: t('board.menuName'),
      },
      {
        icon: (
          <i className={'h-[16px] w-[16px] text-text-title'}>
            <GridSvg></GridSvg>
          </i>
        ),
        onClick: onGridClick,
        title: t('grid.menuName'),
      },
    ],
    [onBoardClick, onDocumentClick, onGridClick, t]
  );

  return (
    <>
      {items.map((item, index) => {
        return (
          <MenuItem key={index} onClick={item.onClick}>
            <div className={'flex items-center gap-2'}>
              {item.icon}
              <span className={'flex-shrink-0'}>{item.title}</span>
            </div>
          </MenuItem>
        );
      })}
    </>
  );
}

export default NewPageMenu;
