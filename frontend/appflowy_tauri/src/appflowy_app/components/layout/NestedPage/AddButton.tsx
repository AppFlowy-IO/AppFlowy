import React, { useMemo } from 'react';
import ButtonPopoverList from '$app/components/_shared/ButtonPopoverList';
import { IconButton } from '@mui/material';
import AddSvg from '$app/components/_shared/svg/AddSvg';
import { useTranslation } from 'react-i18next';
import { DocumentSvg } from '$app/components/_shared/svg/DocumentSvg';
import { GridSvg } from '$app/components/_shared/svg/GridSvg';
import { BoardSvg } from '$app/components/_shared/svg/BoardSvg';
import { ViewLayoutPB } from '@/services/backend';

function AddButton({ isVisible, onAddPage }: { isVisible: boolean; onAddPage: (layout: ViewLayoutPB) => void }) {
  const { t } = useTranslation();
  const options = useMemo(
    () => [
      {
        key: 'add-document',
        label: t('document.menuName'),
        icon: (
          <div className={'h-5 w-5'}>
            <DocumentSvg />
          </div>
        ),
        onClick: () => {
          onAddPage(ViewLayoutPB.Document);
        },
      },
      {
        key: 'add-grid',
        label: t('grid.menuName'),
        icon: (
          <div className={'h-5 w-5'}>
            <GridSvg />
          </div>
        ),
        onClick: () => {
          onAddPage(ViewLayoutPB.Grid);
        },
      },
      {
        key: 'add-board',
        label: t('board.menuName'),
        icon: (
          <div className={'h-5 w-5'}>
            <BoardSvg />
          </div>
        ),
        onClick: () => {
          onAddPage(ViewLayoutPB.Board);
        },
      },
    ],
    [onAddPage, t]
  );

  return (
    <ButtonPopoverList
      popoverOrigin={{
        anchorOrigin: {
          vertical: 'bottom',
          horizontal: 'left',
        },
        transformOrigin: {
          vertical: 'top',
          horizontal: 'left',
        },
      }}
      popoverOptions={options}
      isVisible={isVisible}
    >
      <IconButton className={'mr-2 h-6 w-6'}>
        <AddSvg />
      </IconButton>
    </ButtonPopoverList>
  );
}

export default AddButton;
