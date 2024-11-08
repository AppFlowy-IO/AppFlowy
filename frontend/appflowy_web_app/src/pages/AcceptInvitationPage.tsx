import { Invitation } from '@/application/types';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';
import ChangeAccount from '@/components/_shared/modal/ChangeAccount';
import { notify } from '@/components/_shared/notify';
import { getAvatar } from '@/components/_shared/view-icon/utils';
import { AFConfigContext, useCurrentUser, useService } from '@/components/main/app.hooks';
import { openOrDownload } from '@/utils/open_schema';
import { openAppFlowySchema } from '@/utils/url';
import { EmailOutlined } from '@mui/icons-material';
import { Avatar, Button, Divider } from '@mui/material';
import React, { useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useSearchParams } from 'react-router-dom';

function AcceptInvitationPage () {
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated;
  const currentUser = useCurrentUser();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const invitationId = searchParams.get('invited_id');
  const service = useService();
  const [invitation, setInvitation] = useState<Invitation>();
  const [modalOpened, setModalOpened] = useState(false);
  const { t } = useTranslation();

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login?redirectTo=' + encodeURIComponent(window.location.href));
    }
  }, [isAuthenticated, navigate]);

  const loadInvitation = useCallback(async (invitationId: string) => {
    if (!service) return;
    try {
      const res = await service.getInvitation(invitationId);

      if (res.status === 'Accepted') {
        notify.warning(t('invitation.alreadyAccepted'));
      }

      setInvitation(res);
      // eslint-disable-next-line
    } catch (e: any) {
      setModalOpened(true);
    }
  }, [service, t]);

  useEffect(() => {
    if (!invitationId) return;
    void loadInvitation(invitationId);
  }, [loadInvitation, invitationId]);

  const workspaceIconProps = useMemo(() => {
    if (!invitation) return {};

    return getAvatar({
      icon: invitation.workspace_icon,
      name: invitation.workspace_name,
    });
  }, [invitation]);

  const inviterIconProps = useMemo(() => {
    if (!invitation) return {};

    return getAvatar({
      icon: invitation.inviter_icon,
      name: invitation.inviter_name,
    });
  }, [invitation]);

  return (
    <div
      className={'text-text-title px-6 max-md:gap-4 flex flex-col gap-12 h-screen appflowy-scroller w-screen overflow-x-hidden overflow-y-auto items-center bg-bg-base'}
    >
      <div
        onClick={() => {
          navigate('/app');
        }}
        className={'flex w-full cursor-pointer max-md:justify-center max-md:h-32 h-20 items-center justify-between sticky'}
      >
        <AppflowyLogo className={'w-32 h-12 max-md:w-52'} />
      </div>
      <div className={'flex w-full max-w-[560px] flex-col items-center gap-6 text-center'}>
        <Avatar
          className={'h-20 w-20 text-[40px] border border-text-title rounded-[16px]'} {...workspaceIconProps}
          variant="rounded"
        />
        <div
          className={'text-[40px] max-sm:text-[24px] px-4 whitespace-pre-wrap break-words leading-[107%] text-center'}
        >
          {t('invitation.join')}
          {' '}
          <span className={'font-semibold'}>{invitation?.workspace_name}</span>
          {' '}
          {t('invitation.on')}
          {' '}
          <span className={'whitespace-nowrap'}>AppFlowy</span>

        </div>
        <Divider className={'max-w-full w-[400px]'} />
        <div className={'flex items-center justify-center py-1 gap-4'}>
          <Avatar
            className={'h-20 w-20 border border-line-divider text-[40px]'} {...inviterIconProps}
            variant="circular"
          />
          <div className={'flex gap-1 flex-col items-start'}>
            <div className={'text-base'}>{t('invitation.invitedBy')}</div>
            <div className={'text-base font-semibold'}>{invitation?.inviter_name}</div>
            <div className={'text-sm text-text-caption'}>{t('invitation.membersCount', {
              count: invitation?.member_count || 0,
            })}</div>
          </div>
        </div>
        <div className={'text-sm max-w-full w-[400px] text-text-title'}>
          {t('invitation.tip')}
        </div>
        <div
          className={'border-b max-sm:border max-sm:rounded-[8px] border-line-border flex items-center gap-2 max-w-full py-2 px-4 w-[400px] bg-bg-body'}
        >
          <EmailOutlined />
          {currentUser?.email}
        </div>

        <Button
          variant={'contained'}
          color={'primary'}
          size={'large'}
          className={'max-w-full w-[400px] rounded-[16px] text-[24px] py-5 px-10'}
          onClick={async () => {
            if (!invitationId) return;
            if (invitation?.status === 'Accepted') {
              notify.warning(t('invitation.alreadyAccepted'));
              return;
            }

            try {
              await service?.acceptInvitation(invitationId);
              notify.info({
                type: 'success',
                title: t('invitation.success'),
                message: t('invitation.successMessage'),
                okText: t('invitation.openWorkspace'),

                onOk: () => {
                  openOrDownload(openAppFlowySchema + '#workspace_id=' + invitation?.workspace_id);
                },
              });

            } catch (e) {
              notify.error('Failed to join workspace');
            }
          }}
        >
          {t('invitation.joinWorkspace')}
        </Button>
      </div>
      <ChangeAccount setModalOpened={setModalOpened} modalOpened={modalOpened} />
    </div>
  );
}

export default AcceptInvitationPage;