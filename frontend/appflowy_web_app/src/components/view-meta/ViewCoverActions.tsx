import { ViewMetaCover } from '@/application/types';
import { PopoverProps } from '@mui/material/Popover';
import React, { forwardRef, useState } from 'react';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import CoverPopover from '@/components/view-meta/CoverPopover';

function ViewCoverActions (
  { show, onRemove, onUpdateCover }: {
    show: boolean;
    onRemove: () => void;
    onUpdateCover: (cover: ViewMetaCover) => void;
  },
  ref: React.ForwardedRef<HTMLDivElement>,
) {
  const { t } = useTranslation();
  const [anchorPosition, setAnchorPosition] = useState<PopoverProps['anchorPosition']>(undefined);
  const showPopover = Boolean(anchorPosition);

  return (
    <>
      <div className={'absolute bottom-0 left-1/2 w-[964px] min-w-0 max-w-full -translate-x-1/2 transform'}>
        <div
          ref={ref}
          className={`absolute ${show ? 'flex' : 'opacity-0'} bottom-4 right-0 items-center space-x-2 p-2`}
        >
          <div className={'flex items-center space-x-2'}>
            <Button
              onClick={(event) => setAnchorPosition({
                top: event.clientY,
                left: event.clientX,
              })}
              className={'min-w-0 p-1.5 h-[32px]'}
              size={'small'}
              variant={'contained'}
              color={'inherit'}
            >
              {t('document.plugins.cover.changeCover')}
            </Button>
            <Button
              variant={'contained'}
              size={'small'}
              className={'min-h-0 min-w-0 p-1.5 h-[32px] w-[32px]'}
              sx={{
                '.MuiButton-startIcon': {
                  marginRight: '0px',
                },
              }}
              onClick={() => {
                onRemove();
                setAnchorPosition(undefined);
              }}
              color={'inherit'}
              startIcon={<DeleteIcon />}
            />
          </div>
        </div>

      </div>
      {showPopover && <CoverPopover
        anchorPosition={anchorPosition}
        open={
          showPopover
        }
        onClose={
          () => setAnchorPosition(undefined)
        }
        onUpdateCover={onUpdateCover}
      />}
    </>
  );
}

export default forwardRef(ViewCoverActions);
