import { Invitation } from '@/application/types';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { AFConfigContext, useCurrentUser, useService } from '@/components/main/app.hooks';
import { stringAvatar } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import { openOrDownload } from '@/utils/open_schema';
import { openAppFlowySchema } from '@/utils/url';
import { EmailOutlined } from '@mui/icons-material';
import { Avatar, Button, Divider } from '@mui/material';
import React, { useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';
import { ReactComponent as ErrorIcon } from '@/assets/error.svg';

function AcceptInvitationPage () {
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated;
  const currentUser = useCurrentUser();
  const navigate = useNavigate();
  const openLoginModal = useContext(AFConfigContext)?.openLoginModal;
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
      <div className={'flex w-full max-md:justify-center max-md:h-32 h-20 items-center justify-between sticky'}>
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
          <span className={'font-semibold'}>{currentUser?.name}</span>
          {' '}
          {t('invitation.on')}
          {' '}
          <span className={'whitespace-nowrap'}>{invitation?.workspace_name}</span>

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
      <NormalModal
        onCancel={() => {
          setModalOpened(false);
          navigate('/');
        }}
        closable={false}
        cancelText={t('invitation.errorModal.close')}
        onOk={openLoginModal}
        okText={t('invitation.errorModal.changeAccount')}
        title={<div className={'text-left font-bold flex gap-2 items-center'}>
          <ErrorIcon className={'w-5 h-5 text-function-error'} />
          {t('invitation.errorModal.title')}
        </div>}
        open={modalOpened}
      >
        <div className={'text-text-title flex flex-col text-sm gap-1 whitespace-pre-wrap break-words'}>
          {t('invitation.errorModal.description', {
            email: currentUser?.email,
          })}
        </div>
      </NormalModal>
    </div>
  );
}

function getAvatar (item: {
  icon?: string;
  name: string;
}) {
  if (item.icon) {
    const isFlag = isFlagEmoji(item.icon);

    return {
      children: <span className={isFlag ? 'icon' : ''}>{item.icon}</span>,
      sx: {
        bgcolor: 'var(--bg-body)',
        color: 'var(--text-title)',
      },
    };
  }

  return stringAvatar(item.name || '');
}

export default AcceptInvitationPage;