import React, { useMemo } from 'react';
import ButtonPopoverList from '$app/components/_shared/ButtonPopoverList';
import { IconButton } from '@mui/material';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
import { ReactComponent as GridSvg } from '$app/assets/grid.svg';
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
      <IconButton size={'small'}>
        <AddSvg />
      </IconButton>
    </ButtonPopoverList>
  );
}

export default AddButton;
