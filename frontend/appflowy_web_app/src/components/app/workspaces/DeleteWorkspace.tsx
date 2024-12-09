import React from 'react';
import { Button } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DeleteSvg } from '@/assets/trash.svg';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/main/app.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';

function DeleteWorkspace({workspaceId, name}: {
  name: string;
  workspaceId: string;
}) {
  const {t} = useTranslation();
  const [confirmOpen, setConfirmOpen] = React.useState(false);
  const [loading, setLoading] = React.useState(false);
  const service = useService();
  const currentWorkspaceId = useCurrentWorkspaceId();

  const handleOk = async() => {
    if (!service) return;

    try {
      setLoading(true);
      await service.deleteWorkspace(workspaceId);
      setConfirmOpen(false);
      if (currentWorkspaceId === workspaceId) {
        window.location.href = `/app`
      }
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <Button onClick={() => {
        setConfirmOpen(true);
      }} className={'w-full justify-start hover:text-function-error'} size={'small'} color={'inherit'} startIcon={<DeleteSvg />}>
        {t('button.delete')}
      </Button>
      <NormalModal
        okLoading={loading}
        onOk={handleOk}
        danger={true}
        okText={t('button.delete')}
        title={<div className={'flex items-center font-medium'}>
          {t('button.delete')}: {name}
        </div>}
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
      >
        {t('workspace.deleteWorkspaceHintText')}
      </NormalModal>
    </>
  );
}

export default DeleteWorkspace;