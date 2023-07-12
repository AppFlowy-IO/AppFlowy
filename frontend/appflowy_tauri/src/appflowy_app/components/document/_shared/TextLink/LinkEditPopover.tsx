import React, { useCallback } from 'react';
import Popover from '@mui/material/Popover';
import { DeleteOutline, Done } from '@mui/icons-material';
import EditLink from '$app/components/document/_shared/TextLink/EditLink';
import { useAppDispatch } from '$app/stores/store';
import { linkPopoverActions, rangeActions } from '$app_reducers/document/slice';
import { formatLinkThunk } from '$app_reducers/document/async-actions/link';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useSubscribeLinkPopover } from '$app/components/document/_shared/SubscribeLinkPopover.hooks';
import Button from '@mui/material/Button';
import { useTranslation } from 'react-i18next';

function LinkEditPopover() {
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();
  const { t } = useTranslation();
  const popoverState = useSubscribeLinkPopover();
  const { anchorPosition, id, selection, title = '', href = '', open = false } = popoverState;

  const onClose = useCallback(() => {
    dispatch(linkPopoverActions.closeLinkPopover(docId));
  }, [dispatch, docId]);

  const onExited = useCallback(() => {
    if (!id || !selection) return;
    const newSelection = {
      index: selection.index,
      length: title.length,
    };

    dispatch(
      rangeActions.setRange({
        docId,
        id,
        rangeStatic: newSelection,
      })
    );
    dispatch(
      rangeActions.setCaret({
        docId,
        caret: {
          id,
          ...newSelection,
        },
      })
    );
  }, [docId, id, selection, title, dispatch]);

  const onChange = useCallback(
    (newVal: { href?: string; title: string }) => {
      if (!id) return;
      if (newVal.title === title && newVal.href === href) return;

      dispatch(
        linkPopoverActions.updateLinkPopover({
          docId,
          linkState: {
            id,
            href: newVal.href,
            title: newVal.title,
          },
        })
      );
    },
    [docId, dispatch, href, id, title]
  );

  const onDone = useCallback(async () => {
    if (!controller) return;
    await dispatch(
      formatLinkThunk({
        controller,
      })
    );
    onClose();
  }, [controller, dispatch, onClose]);

  return (
    <Popover
      onMouseDown={(e) => e.stopPropagation()}
      open={open}
      disableAutoFocus={true}
      anchorReference='anchorPosition'
      anchorPosition={anchorPosition}
      TransitionProps={{
        onExited,
      }}
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
          text={t('document.inlineLink.url.label')}
          value={href}
          onChange={(link) => {
            onChange({
              href: link,
              title,
            });
          }}
        />
        <EditLink
          text={t('document.inlineLink.title.label')}
          value={title}
          onChange={(text) =>
            onChange({
              href,
              title: text,
            })
          }
        />
        <div className={'flex items-center justify-end'}>
          <Button onClick={onDone}>
            <Done />
            {t('button.done')}
          </Button>
        </div>
      </div>
    </Popover>
  );
}

export default LinkEditPopover;
