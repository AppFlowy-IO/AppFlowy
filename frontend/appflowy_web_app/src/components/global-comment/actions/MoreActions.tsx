import { GlobalComment } from '@/application/comment.type';
import { PublishContext } from '@/application/publish';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { Popover } from '@/components/_shared/popover';
import { AFConfigContext } from '@/components/app/app.hooks';
import { useGlobalCommentContext } from '@/components/global-comment/GlobalComment.hooks';
import { Button, IconButton, Tooltip, TooltipProps } from '@mui/material';
import React, { memo, useCallback, useContext, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as MoreIcon } from '@/assets/more.svg';
import { ReactComponent as TrashIcon } from '@/assets/trash.svg';

interface Item {
  Icon: React.FC<React.SVGProps<SVGSVGElement>>;
  label: string;
  disabled: boolean;
  onClick: () => void;
  danger?: boolean;
  tooltip?: TooltipProps;
}

function MoreActions({ comment }: { comment: GlobalComment }) {
  const { reload } = useGlobalCommentContext();
  const canDeleted = comment.canDeleted;

  const ref = React.useRef<HTMLButtonElement>(null);
  const [open, setOpen] = React.useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = React.useState(false);
  const handleClose = useCallback(() => {
    setOpen(false);
  }, []);

  const handleOpen = () => {
    setOpen(true);
  };

  const { t } = useTranslation();
  const service = useContext(AFConfigContext)?.service;
  const viewId = useContext(PublishContext)?.viewMeta?.view_id;

  const handleDeleteAction = useCallback(async () => {
    if (!viewId || !service) return;
    try {
      await service?.deleteCommentOnPublishView(viewId, comment.commentId);
      await reload();
    } catch (e) {
      console.error(e);
      notify.error('Failed to delete comment');
    } finally {
      setDeleteModalOpen(false);
    }
  }, [comment.commentId, reload, service, viewId]);

  const actions = useMemo(() => {
    return [
      {
        Icon: TrashIcon,
        label: t('button.delete'),
        disabled: !canDeleted,
        tooltip: canDeleted
          ? undefined
          : {
              title: <div className={'text-center'}>{t('globalComment.noAccessDeleteComment')}</div>,
              placement: 'top',
            },
        onClick: () => {
          setDeleteModalOpen(true);
        },
        danger: true,
      },
    ] as Item[];
  }, [t, canDeleted]);

  const renderItem = useCallback((action: Item) => {
    return (
      <Button
        size={'small'}
        color={'inherit'}
        disabled={action.disabled}
        onClick={action.onClick}
        className={`w-full items-center justify-start gap-2 p-1 ${action.danger ? 'hover:text-function-error' : ''}`}
      >
        <action.Icon className={'h-4 w-4'} />
        <div>{action.label}</div>
      </Button>
    );
  }, []);

  return (
    <>
      <IconButton ref={ref} size={'small'} onClick={handleOpen} className={'h-full'}>
        <MoreIcon className={'h-5 w-5'} />
      </IconButton>
      <Popover
        anchorEl={ref.current}
        open={open}
        onClose={handleClose}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        transformOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <div className={'flex min-w-[150px] flex-col items-start p-2'}>
          {actions.map((action, index) => {
            if (action.tooltip) {
              return (
                <Tooltip key={index} {...action.tooltip}>
                  <div className={'w-full'}>{renderItem(action)}</div>
                </Tooltip>
              );
            }

            return (
              <div key={index} className={'w-full'}>
                {renderItem(action)}
              </div>
            );
          })}
        </div>
      </Popover>

      {deleteModalOpen && (
        <NormalModal
          PaperProps={{
            sx: {
              maxWidth: 420,
            },
          }}
          okText={t('button.delete')}
          danger={true}
          onOk={handleDeleteAction}
          onCancel={() => {
            setDeleteModalOpen(false);
          }}
          onClose={() => setDeleteModalOpen(false)}
          open={deleteModalOpen}
          title={<div className={'text-left'}>{t('globalComment.deleteComment')}</div>}
        >
          <div className={'w-full whitespace-pre-wrap break-words pb-1 text-text-caption'}>
            {t('globalComment.confirmDeleteDescription')}
          </div>
        </NormalModal>
      )}
    </>
  );
}

export default memo(MoreActions);
