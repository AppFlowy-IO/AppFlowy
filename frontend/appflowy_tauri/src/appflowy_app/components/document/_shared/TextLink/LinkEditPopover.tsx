import React, { useCallback, useContext } from 'react';
import Popover from '@mui/material/Popover';
import { Divider } from '@mui/material';
import Button from '@mui/material/Button';
import { DeleteOutline } from '@mui/icons-material';
import EditLink from '$app/components/document/_shared/TextLink/EditLink';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { linkPopoverActions, rangeActions } from '$app_reducers/document/slice';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { updateLinkThunk } from '$app_reducers/document/async-actions';

function LinkEditPopover() {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
  const popoverState = useAppSelector((state) => state.documentLinkPopover);
  const { anchorPosition, id, selection, title = '', href = '', open = false } = popoverState;

  const onClose = useCallback(() => {
    if (!id || !selection) return;
    dispatch(
      rangeActions.setRange({
        id,
        rangeStatic: selection,
      })
    );
    dispatch(
      rangeActions.setCaret({
        id,
        ...selection,
      })
    );
    dispatch(linkPopoverActions.closeLinkPopover());
  }, [dispatch, id, selection]);

  const onChange = useCallback(
    (newVal: { href?: string; title: string }) => {
      if (!controller || !id || !selection) return;
      if (newVal.title === title && newVal.href === href) return;
      dispatch(
        updateLinkThunk({
          id,
          href: newVal.href,
          title: newVal.title,
          selection,
          controller,
        })
      );
    },
    [controller, dispatch, href, id, selection, title]
  );

  return (
    <Popover
      onMouseDown={(e) => e.stopPropagation()}
      open={open}
      disableAutoFocus={true}
      anchorReference='anchorPosition'
      anchorPosition={anchorPosition}
      onClose={onClose}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'center',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
      PaperProps={{
        sx: {
          width: 500,
        },
      }}
    >
      <div className='flex flex-col p-3'>
        <EditLink
          text={'URL'}
          value={href}
          onComplete={(link) => {
            onChange({
              href: link,
              title,
            });
            onClose();
          }}
        />
        <EditLink
          text={'Link title'}
          value={title}
          onChange={(text) =>
            onChange({
              href,
              title: text,
            })
          }
        />
        <Divider />
        <div className={'pt-1'}>
          <Button
            className={'w-[100%]'}
            style={{
              justifyContent: 'flex-start',
            }}
            startIcon={<DeleteOutline />}
            onClick={() => {
              onChange({
                title,
              });
              onClose();
            }}
          >
            Remove link
          </Button>
        </div>
      </div>
    </Popover>
  );
}

export default LinkEditPopover;
