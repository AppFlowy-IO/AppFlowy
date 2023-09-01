import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { Align } from '$app/interfaces/document';
import { FormatAlignCenter, FormatAlignLeft, FormatAlignRight } from '@mui/icons-material';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import Popover from '@mui/material/Popover';
import { useTranslation } from 'react-i18next';
import { Tooltip } from '@mui/material';

function ImageAlign({
  id,
  align,
  onOpen,
  onClose,
}: {
  id: string;
  align: Align;
  onOpen: () => void;
  onClose: () => void;
}) {
  const ref = useRef<HTMLDivElement | null>(null);
  const [anchorEl, setAnchorEl] = useState<HTMLDivElement>();
  const popoverOpen = Boolean(anchorEl);
  const { t } = useTranslation();

  useEffect(() => {
    if (popoverOpen) {
      onOpen();
    } else {
      onClose();
    }
  }, [onClose, onOpen, popoverOpen]);

  const dispatch = useAppDispatch();
  const { controller } = useSubscribeDocument();
  const renderAlign = (align: Align) => {
    switch (align) {
      case Align.Left:
        return <FormatAlignLeft />;
      case Align.Center:
        return <FormatAlignCenter />;
      default:
        return <FormatAlignRight />;
    }
  };

  const updateAlign = useCallback(
    (align: Align) => {
      dispatch(
        updateNodeDataThunk({
          id,
          data: {
            align,
          },
          controller,
        })
      );
      setAnchorEl(undefined);
    },
    [controller, dispatch, id]
  );

  return (
    <>
      <Tooltip disableInteractive placement={'top'} title={t('document.plugins.optionAction.align')}>
        <div
          ref={ref}
          className='flex items-center justify-center p-1'
          onClick={(_) => {
            ref.current && setAnchorEl(ref.current);
          }}
        >
          {renderAlign(align)}
        </div>
      </Tooltip>
      <Popover
        open={popoverOpen}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'center',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'center',
        }}
        onMouseDown={(e) => e.stopPropagation()}
        anchorEl={anchorEl}
        onClose={() => setAnchorEl(undefined)}
        PaperProps={{
          style: {
            backgroundColor: 'var(--bg-body)',
          },
        }}
      >
        <div className='flex items-center justify-center p-1'>
          {[Align.Left, Align.Center, Align.Right].map((item: Align) => {
            return (
              <div
                key={item}
                style={{
                  color: align === item ? '#00BCF0' : '#fff',
                }}
                className={'cursor-pointer'}
                onClick={() => {
                  updateAlign(item);
                }}
              >
                {renderAlign(item)}
              </div>
            );
          })}
        </div>
      </Popover>
    </>
  );
}

export default ImageAlign;
