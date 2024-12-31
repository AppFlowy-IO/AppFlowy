import React from 'react';
import { Button } from '@mui/material';
import { useTranslation } from 'react-i18next';
import { ReactComponent as LeaveSvg } from '@/assets/leave.svg';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/main/app.hooks';
import { useCurrentWorkspaceId } from '@/components/app/app.hooks';

function LeaveWorkspace({workspaceId}: {
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
       await service.leaveWorkspace(workspaceId);
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
      }} size={'small'} className={'w-full justify-start hover:text-function-error'} color={'inherit'} startIcon={<LeaveSvg />}>
        {t('workspace.leaveCurrentWorkspace')}
      </Button>
      <NormalModal
        okLoading={loading}
        onOk={handleOk}
        danger={true}
        okText={t('button.yes')}
        title={<div className={'flex items-center font-medium'}>
          {t('workspace.leaveCurrentWorkspace')}
        </div>}
        open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
      >
        {t('workspace.leaveCurrentWorkspacePrompt')}
      </NormalModal>
    </>
  );
}

export default LeaveWorkspace;