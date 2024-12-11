import { View } from '@/application/types';
import { CircularProgress, IconButton, Tooltip } from '@mui/material';
import React from 'react';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { ReactComponent as AddIcon } from '@/assets/add.svg';
import { useTranslation } from 'react-i18next';

function SpaceActions({
  onClickMore,
  onClickAdd,
}: {
  view: View;
  onClickAdd: (e: React.MouseEvent<HTMLElement>) => Promise<void>;
  onClickMore: (e: React.MouseEvent<HTMLElement>) => void;
}) {

  const { t } = useTranslation();
  const [loading, setLoading] = React.useState<boolean>(false);

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
          <MoreIcon/>
        </IconButton>
      </Tooltip>
      <Tooltip
        disableInteractive={true}
        title={t('sideBar.addAPage')}
      >
        {loading ? <CircularProgress size={16}/> : <IconButton
          onClick={async (e) => {
            e.stopPropagation();
            setLoading(true);
            try {
              await onClickAdd(e);
            } finally {
              setLoading(false);
            }
          }}
          size={'small'}
        >
          <AddIcon/>
        </IconButton>}

      </Tooltip>
    </div>
  );
}

export default SpaceActions;