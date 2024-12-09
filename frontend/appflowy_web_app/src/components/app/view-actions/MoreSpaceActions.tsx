import { View } from '@/application/types';
import CreateSpaceModal from '@/components/app/view-actions/CreateSpaceModal';
import DeleteSpaceConfirm from '@/components/app/view-actions/DeleteSpaceConfirm';
import ManageSpace from '@/components/app/view-actions/ManageSpace';
import { Button, Divider } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteIcon } from '@/assets/trash.svg';
import { ReactComponent as DuplicateIcon } from '@/assets/duplicate.svg';
import { ReactComponent as SettingsIcon } from '@/assets/settings.svg';
import { ReactComponent as AddIcon } from '@/assets/add.svg';

function MoreSpaceActions ({
  view,
  onClose,
}: {
  view: View;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const [deleteModalOpen, setDeleteModalOpen] = React.useState(false);
  const [manageModalOpen, setManageModalOpen] = React.useState(false);
  const [createSpaceModalOpen, setCreateSpaceModalOpen] = React.useState(false);
  const actions = useMemo(() => {
    return [{
      label: t('space.manage'),
      icon: <SettingsIcon />,
      onClick: () => {
        setManageModalOpen(true);
      },
    }, {
      label: t('space.duplicate'),
      icon: <DuplicateIcon />,
      hidden: true,
      onClick: () => {
        //
      },
    }
    ];
  }, [t]);

  return (
    <div className={'flex flex-col gap-2 w-full p-1.5 min-w-[230px]'}>
      {actions.map(action => (
        <Button
          key={action.label}
          size={'small'}
          onClick={action.onClick}
          className={`px-3 py-1 ${action.hidden ? 'hidden' : ''} justify-start `}
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
          setCreateSpaceModalOpen(true);
        }}
        startIcon={<AddIcon className={'w-4 h-4'} />}
      >
        {t('space.createNewSpace')}
      </Button>
      <Divider className={'w-full'} />
      <Button
        size={'small'}
        className={'px-3 py-1 hover:text-function-error justify-start'}
        color={'inherit'}
        onClick={() => {
          setDeleteModalOpen(true);
        }}
        startIcon={<DeleteIcon className={'w-4 h-4'} />}
      >
        {t('button.delete')}
      </Button>
      <ManageSpace
        open={manageModalOpen}
        onClose={() => {
          setManageModalOpen(false);
          onClose();
        }}
        viewId={view.view_id}
      />
      <CreateSpaceModal
        onCreated={onClose}
        open={createSpaceModalOpen}
        onClose={() => setCreateSpaceModalOpen(false)}
      />
      <DeleteSpaceConfirm
        viewId={view.view_id}
        open={deleteModalOpen}
        onClose={() => {
          setDeleteModalOpen(false);
          onClose();
        }}
      />
    </div>
  );
}

export default MoreSpaceActions;