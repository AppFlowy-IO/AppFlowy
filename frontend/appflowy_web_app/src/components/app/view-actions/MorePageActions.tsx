import { View, ViewIconType } from '@/application/types';
import { ReactComponent as EditIcon } from '@/assets/edit.svg';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { ReactComponent as DuplicateIcon } from '@/assets/duplicate.svg';
import { ReactComponent as ChangeIcon } from '@/assets/change_icon.svg';
import { ReactComponent as MoveToIcon } from '@/assets/move_to.svg';
import { ReactComponent as OpenInBrowserIcon } from '@/assets/open_in_browser.svg';
import { notify } from '@/components/_shared/notify';
import { useAppHandlers, useCurrentWorkspaceId } from '@/components/app/app.hooks';
import DeletePageConfirm from '@/components/app/view-actions/DeletePageConfirm';
import MovePagePopover from '@/components/app/view-actions/MovePagePopover';
import RenameModal from '@/components/app/view-actions/RenameModal';

import { Button, Divider } from '@mui/material';
import { PopoverProps } from '@mui/material/Popover';
import React, { lazy, Suspense, useCallback, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';

const ChangeIconPopover = lazy(() => import('@/components/_shared/view-icon/ChangeIconPopover'));

const popoverProps: Partial<PopoverProps> = {
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
  anchorOrigin: {
    vertical: 'top',
    horizontal: 'right',
  },
};

function MorePageActions ({ view, onDeleted, onMoved }: {
  view: View;
  onDeleted?: () => void;
  onMoved?: () => void;
}) {
  const currentWorkspaceId = useCurrentWorkspaceId();

  const [iconPopoverAnchorEl, setIconPopoverAnchorEl] = useState<null | HTMLElement>(null);
  const openIconPopover = Boolean(iconPopoverAnchorEl);

  const [renameModalOpen, setRenameModalOpen] = useState(false);
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [movePopoverAnchorEl, setMovePopoverAnchorEl] = useState<null | HTMLElement>(null);
  const {
    updatePage,
  } = useAppHandlers();
  const { t } = useTranslation();

  const handleChangeIcon = useCallback(async (icon: { ty: ViewIconType, value: string }) => {
    try {
      await updatePage?.(view.view_id, {
        icon: icon,
        name: view.name,
        extra: view.extra || {},
      });
      setIconPopoverAnchorEl(null);

      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e);
    }
  }, [updatePage, view.extra, view.name, view.view_id]);

  const handleRemoveIcon = useCallback(() => {
    void handleChangeIcon({ ty: 0, value: '' });
  }, [handleChangeIcon]);

  const actions = useMemo(() => {
    return [{
      label: t('button.rename'),
      icon: <EditIcon />,
      onClick: () => {
        setRenameModalOpen(true);
      },
    }, {
      label: t('disclosureAction.changeIcon'),
      icon: <ChangeIcon />,
      onClick: (e: React.MouseEvent<HTMLButtonElement>) => {
        setIconPopoverAnchorEl(e.currentTarget);
      },
    }, {
      label: t('button.duplicate'),
      icon: <DuplicateIcon />,
      onClick: () => {
        //
      },
    }, {
      label: t('disclosureAction.moveTo'),
      icon: <MoveToIcon />,
      onClick: (e: React.MouseEvent<HTMLButtonElement>) => {
        setMovePopoverAnchorEl(e.currentTarget);
      },
    }, {
      label: t('button.delete'),
      icon: <DeleteIcon />,
      danger: true,
      onClick: () => {
        setDeleteModalOpen(true);
      },
    }];
  }, [t]);

  return (
    <div className={'flex flex-col gap-2 w-full p-1.5 min-w-[230px]'}>
      {actions.map(action => (
        <Button
          key={action.label}
          size={'small'}
          onClick={action.onClick}
          className={`px-3 py-1 justify-start ${action.danger ? 'hover:text-function-error' : ''}`}
          color={'inherit'}
          startIcon={action.icon}
        >
          {action.label}
        </Button>
      ))}
      <Divider className={'w-full'} />
      <Button
        size={'small'}

        className={'px-3 py-1 justify-start'}
        color={'inherit'}
        onClick={() => {
          if (!currentWorkspaceId) return;
          window.open(`/app/${currentWorkspaceId}/${view.view_id}`, '_blank');
        }}
        startIcon={<OpenInBrowserIcon className={'w-4 h-4'} />}
      >
        {t('disclosureAction.openNewTab')}
      </Button>
      <Suspense fallback={null}>
        <ChangeIconPopover
          iconEnabled={false}
          defaultType={'emoji'}
          open={openIconPopover}
          anchorEl={iconPopoverAnchorEl}
          onClose={() => {
            setIconPopoverAnchorEl(null);
          }}
          popoverProps={popoverProps}
          onSelectIcon={handleChangeIcon}
          removeIcon={handleRemoveIcon}
        />
      </Suspense>
      <RenameModal
        open={renameModalOpen}
        onClose={() => setRenameModalOpen(false)}
        viewId={view.view_id}
      />
      <DeletePageConfirm
        open={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        viewId={view.view_id}
        onDeleted={onDeleted}
      />
      <MovePagePopover
        {...popoverProps} viewId={view.view_id}
        open={Boolean(movePopoverAnchorEl)}
        anchorEl={movePopoverAnchorEl}
        onClose={() => setMovePopoverAnchorEl(null)}
        onMoved={onMoved}
      />
    </div>
  );
}

export default MorePageActions;