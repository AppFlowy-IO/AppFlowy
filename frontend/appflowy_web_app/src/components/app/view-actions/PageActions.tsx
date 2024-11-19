import { View, ViewLayout } from '@/application/types';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { useTranslation } from 'react-i18next';

function PageActions ({
  onClickMore,
  onClickAdd,
  view,
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
        title={t('menuAppHeader.moreButtonToolTip')}
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
      {view.layout === ViewLayout.Document && <Tooltip
        disableInteractive={true}
        title={t('menuAppHeader.addPageTooltip')}
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
      </Tooltip>}

    </div>
  );
}

export default PageActions;