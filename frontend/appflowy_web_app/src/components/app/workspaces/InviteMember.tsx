import React, { useCallback, useEffect, useRef } from 'react';
import { Button, OutlinedInput } from '@mui/material';
import { ReactComponent as AddUserIcon } from '@/assets/add_user.svg';
import { useTranslation } from 'react-i18next';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { useCurrentUser, useService } from '@/components/main/app.hooks';
import { Workspace, WorkspaceMember } from '@/application/types';

function InviteMember({ workspace }: {
  workspace: Workspace;
}) {
  const { t } = useTranslation();
  const [open, setOpen] = React.useState(false);
  const [value, setValue] = React.useState('');
  const [loading, setLoading] = React.useState(false);
  const service = useService();
  const currentWorkspaceId = workspace.id;
  const currentUser = useCurrentUser();
  const memberListRef = useRef<WorkspaceMember[]>([]);
  const isOwner = workspace.owner?.uid.toString() === currentUser?.uid.toString();

  const loadMembers = useCallback(async () => {
    try {
      if (!service || !currentWorkspaceId) return;
      memberListRef.current = await service.getWorkspaceMembers(currentWorkspaceId);
    } catch (e) {
      console.error(e);
    }
  }, [currentWorkspaceId, service]);

  const handleOk = async () => {
    if (!service || !currentWorkspaceId) return;
    try {
      setLoading(true);
      const emails = value.split(',').map(e => e.trim());

      const hadInvited = emails.filter(e => memberListRef.current.find(m => m.email === e));

      if (hadInvited.length > 0) {
        notify.warning(t('inviteMember.inviteAlready', { email: hadInvited[0] }));
        return;
      }

      await service.inviteMembers(currentWorkspaceId, emails);

      setOpen(false);
      notify.success(t('inviteMember.inviteSuccess'));
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (!open) {
      setValue('');
    } else {
      void loadMembers();
    }
  }, [open, loadMembers]);

  if (!isOwner) return null;

  return (
    <>
      <Button

        size={'small'}
        className={'justify-start px-2'}
        color={'inherit'}
        onClick={() => {
          setOpen(true);
        }}
        startIcon={<AddUserIcon/>}
      >{t('settings.appearance.members.inviteMembers')}
      </Button>
      <NormalModal
        classes={{ container: 'items-start max-md:mt-auto max-md:items-center mt-[10%] ' }}
        open={open}
        okLoading={loading}
        okButtonProps={{
          disabled: !value || loading,
        }}
        cancelButtonProps={{
          className: 'hidden',
        }}
        onClose={() => setOpen(false)}
        title={<div className={'flex items-center font-medium w-[320px]'}>
          {t('inviteMember.requestInviteMembers')}
        </div>}
        okText={t('inviteMember.requestInvites')}
        onOk={handleOk}>
        <div className={'text-text-caption mb-8'}>{t('inviteMember.description')}</div>
        <div className={'text-text-caption text-xs mb-1'}>{t('inviteMember.emails')}</div>
        <OutlinedInput
          fullWidth={true} size={'small'} value={value} onChange={e => setValue(e.target.value)}
          placeholder={t('inviteMember.addEmail')}
        />
      </NormalModal>
    </>
  );
}

export default InviteMember;