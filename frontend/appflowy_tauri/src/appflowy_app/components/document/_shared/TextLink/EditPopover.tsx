import React, { useCallback, useContext, useEffect } from 'react';
import Popover from '@mui/material/Popover';
import { Divider } from '@mui/material';
import Button from '@mui/material/Button';
import { DeleteOutline } from '@mui/icons-material';
import EditLink from '$app/components/document/_shared/TextLink/EditLink';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { linkPopoverActions, rangeActions } from '$app_reducers/document/slice';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { getNode, getRangeByIndex } from '$app/utils/document/node';
import { updateLinkThunk } from '$app_reducers/document/async-actions';

function EditPopover() {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
  const popoverState = useAppSelector((state) => state.documentLinkPopover);
  const { anchorPosition, id, selection, title = '', href = '', open = false } = popoverState;

  useEffect(() => {
    // when popover is open, we need to set the range to null but painting the selection
    if (open) {
      dispatch(rangeActions.setCaret(null));
      if (id && selection) {
        dispatch(
          rangeActions.setRange({
            rangeStatic: selection,
            id,
          })
        );
      }
    } else if (id && selection) {
      // when popover is closed, we need to set the range to last painted range
      const node = getNode(id);
      if (!node) return;
      const range = getRangeByIndex(node, selection.index, selection.length);
      if (!range) return;
      const windowSelection = window.getSelection();
      windowSelection?.removeAllRanges();
      windowSelection?.addRange(range);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, dispatch]);

  const onClose = useCallback(() => {
    dispatch(linkPopoverActions.closeLinkPopover());
  }, [dispatch]);

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

export default EditPopover;
