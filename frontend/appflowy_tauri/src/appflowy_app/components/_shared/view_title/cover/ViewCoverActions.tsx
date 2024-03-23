import React, { forwardRef } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteIcon } from '$app/assets/delete.svg';

function ViewCoverActions(
  { show, onRemove, onClickChange }: { show: boolean; onRemove: () => void; onClickChange: () => void },
  ref: React.ForwardedRef<HTMLDivElement>
) {
  const { t } = useTranslation();

  return (
    <div className={'absolute bottom-0 left-1/2 w-[964px] min-w-0 max-w-full -translate-x-1/2 transform'}>
      <div ref={ref} className={`absolute ${show ? 'flex' : 'opacity-0'} bottom-4 right-0 items-center space-x-2 p-2`}>
        <div className={'flex items-center space-x-2'}>
          <Button
            onClick={onClickChange}
            className={'min-w-0 p-1.5'}
            size={'small'}
            variant={'contained'}
            color={'inherit'}
          >
            {t('document.plugins.cover.changeCover')}
          </Button>
          <Button
            variant={'contained'}
            size={'small'}
            className={'min-h-0 min-w-0 p-1.5'}
            sx={{
              '.MuiButton-startIcon': {
                marginRight: '0px',
              },
            }}
            onClick={onRemove}
            color={'inherit'}
            startIcon={<DeleteIcon />}
          />
        </div>
      </div>
    </div>
  );
}

export default forwardRef(ViewCoverActions);
