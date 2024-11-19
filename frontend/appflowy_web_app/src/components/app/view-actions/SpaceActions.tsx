import { View } from '@/application/types';
import { IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useTranslation } from 'react-i18next';

function SpaceActions ({
  onClickMore,
  onClickAdd,
}: {
  view: View;
  onClickAdd: (e: React.MouseEvent<HTMLElement>) => void;
  onClickMore: (e: React.MouseEvent<HTMLElement>) => void;
}) {

  const { t } = useTranslation();

  return (
    <div
      onClick={e => e.stopPropagation()}
      className={'flex items-center px-2'}
    >
      <Tooltip
        disableInteractive={true}
        title={t('space.manage')}
      >
        <IconButton
          onClick={e => {
            e.stopPropagation();
            onClickMore(e);
          }}
          size={'small'}
        >
          <MoreIcon />
        </IconButton>
      </Tooltip>
      <Tooltip
        disableInteractive={true}
        title={t('sideBar.addAPage')}
      >
        <IconButton
          onClick={e => {
            e.stopPropagation();
            onClickAdd(e);
          }}
          size={'small'}
        >
          <AddIcon />
        </IconButton>
      </Tooltip>
    </div>
  );
}

export default SpaceActions;