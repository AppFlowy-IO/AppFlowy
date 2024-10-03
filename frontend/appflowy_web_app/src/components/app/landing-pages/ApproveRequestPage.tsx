import {
  GetRequestAccessInfoResponse,
  RequestAccessInfoStatus,
  SubscriptionInterval,
  SubscriptionPlan,
} from '@/application/types';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';
import { ReactComponent as WarningIcon } from '@/assets/warning.svg';
import { NormalModal } from '@/components/_shared/modal';
import { notify } from '@/components/_shared/notify';
import { getAvatar } from '@/components/_shared/view-icon/utils';
import { AFConfigContext, useService } from '@/components/main/app.hooks';
import { downloadPage } from '@/utils/url';
import { ReactComponent as ArrowCircleRightOutlined } from '@/assets/arrow_circle_right.svg';

import { Avatar, Button, Divider, Paper, Typography } from '@mui/material';
import React, { useCallback, useContext, useEffect, useMemo } from 'react';
import { Trans, useTranslation } from 'react-i18next';
import { useNavigate, useSearchParams } from 'react-router-dom';

const WorkspaceMemberLimitExceededCode = 1027;
const REPEAT_REQUEST_CODE = 1043;

function ApproveRequestPage () {
  const [searchParams] = useSearchParams();
  const [requestInfo, setRequestInfo] = React.useState<GetRequestAccessInfoResponse | null>(null);
  const [currentPlans, setCurrentPlans] = React.useState<SubscriptionPlan[]>([]);
  const isPro = useMemo(() => currentPlans.includes(SubscriptionPlan.Pro), [currentPlans]);
  const requestId = searchParams.get('request_id');
  const service = useService();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [upgradeModalOpen, setUpgradeModalOpen] = React.useState(false);
  const [errorModalOpen, setErrorModalOpen] = React.useState(false);
  const [alreadyProModalOpen, setAlreadyProModalOpen] = React.useState(false);
  const openLoginModal = useContext(AFConfigContext)?.openLoginModal;
  const [clicked, setClicked] = React.useState(false);

  const loadRequestInfo = useCallback(async () => {
    if (!service || !requestId) return;
    try {
      const requestInfo = await service.getRequestAccessInfo(requestId);

      setRequestInfo(requestInfo);

      if (requestInfo.status === RequestAccessInfoStatus.Accepted) {
        notify.warning(t('approveAccess.repeatApproveError'));
        setClicked(true);
      }

      const plans = await service.getActiveSubscription(requestInfo.workspace.id);

      setCurrentPlans(plans);
    } catch (e) {
      setErrorModalOpen(true);
      setClicked(true);
    }
  }, [t, requestId, service]);

  const handleApprove = useCallback(async () => {
    if (!service || !requestId) return;
    try {
      await service.approveRequestAccess(requestId);
      notify.success(t('approveAccess.approveSuccess'));
      // eslint-disable-next-line
    } catch (e: any) {
      if (e.code === WorkspaceMemberLimitExceededCode) {
        setUpgradeModalOpen(true);
      }

      if (e.code === REPEAT_REQUEST_CODE) {
        notify.error(t('approveAccess.repeatApproveError'));
        return;
      }

      notify.error(t('approveAccess.approveError'));
    }
  }, [requestId, service, t]);

  const handleUpgrade = useCallback(async () => {
    if (!service || !requestInfo) return;
    const workspaceId = requestInfo.workspace.id;

    if (!workspaceId) return;

    if (isPro) {
      setAlreadyProModalOpen(true);
      return;
    }

    const plan = SubscriptionPlan.Pro;

    try {
      const link = await service.getSubscriptionLink(workspaceId, plan, SubscriptionInterval.Month);

      window.open(link, '_blank');
    } catch (e) {
      notify.error('Failed to get subscription link');
    }
  }, [requestInfo, service, isPro]);

  const workspaceAvatar = useMemo(() => {
    if (!requestInfo) return null;
    return getAvatar({
      name: requestInfo.workspace.name,
      icon: requestInfo.workspace.icon,
    });
  }, [requestInfo]);

  const requesterAvatar = useMemo(() => {
    if (!requestInfo) return null;
    return getAvatar({
      name: requestInfo.requester.name,
      icon: requestInfo.requester.avatarUrl || undefined,
    });
  }, [requestInfo]);

  useEffect(() => {
    void loadRequestInfo();
  }, [loadRequestInfo]);

  return (
    <div className={'m-0 flex h-screen w-screen items-center justify-center bg-bg-body p-0'}>
      <div className={'flex flex-col px-6 items-center gap-3 text-center max-w-[660px] mb-10'}>
        <Typography
          variant="h3" className={'mb-[27px] flex items-center gap-4 text-text-title'} gutterBottom
        >
          <>
            <AppflowyLogo className={'w-48'} />
          </>
        </Typography>

        <div className={'mb-[16px] max-md:text-[24px] text-[52px] font-semibold leading-[128%] text-text-title'}>
          {t('approveAccess.title')}
        </div>
        <div className={'flex max-md:flex-col gap-6 items-center justify-center'}>
          <Paper
            onClick={() => {
              window.open(`mailto:${requestInfo?.requester.email}`, '_blank');
            }}
            className={'border transform transition-all border-line-divider hover:scale-110 flex w-[250px] max-md:w-full hover:bg-fill-list-hover cursor-pointer overflow-hidden items-center flex-1 gap-4 p-6'}
          >
            <Avatar className={'border-2 border-text-title w-12 h-12'} {...requesterAvatar} />
            <div className={'flex flex-col flex-1 overflow-hidden items-start gap-2'}>
              <div
                className={'text-fill-default text-left w-full truncate font-semibold text-sm'}
              >@{requestInfo?.requester.name}</div>
              <div
                className={'text-text-caption text-left truncate w-full text-xs'}
              >{requestInfo?.requester.email}</div>
            </div>
          </Paper>
          <ArrowCircleRightOutlined className={'w-12 max-md:rotate-90 max-md:transform h-12 text-text-title'} />
          <Paper
            onClick={() => {
              window.open(`${window.origin}/app/${requestInfo?.workspace?.id}/${requestInfo?.view?.view_id}`, '_blank');
            }}
            className={'border border-line-divider transform transition-all hover:scale-110 flex overflow-hidden flex-1 cursor-pointer hover:bg-fill-list-hover items-center gap-4 p-6'}
          >
            <Avatar variant={'rounded'} className={'border-2 border-text-title w-12 h-12'} {...workspaceAvatar} />
            <div className={'flex flex-col flex-1 overflow-hidden items-start gap-2'}>
              <div
                className={'text-text-title text-left w-full truncate font-semibold text-sm'}
              >{requestInfo?.workspace.name}</div>
              <div className={'text-text-caption text-left w-full truncate text-xs'}>{t('approveAccess.memberCount', {
                count: requestInfo?.workspace.memberCount || 0,
              })}</div>
            </div>
          </Paper>

        </div>

        <div className={'flex items-center mt-4 w-full gap-4 justify-between'}>
          <Button
            onClick={() => {
              void handleApprove();
              setClicked(true);
            }}
            disabled={clicked || !requestInfo}
            className={'flex-1 py-2 px-4 rounded-[8px] text-[20px] font-medium max-md:text-base max-sm:text-[14px] max-md:py-2'}
            variant={'contained'} color={'primary'}
          >
            {t('approveAccess.approveButton')}
          </Button>
          <Button
            onClick={() => {
              navigate('/');
            }}
            className={'flex-1 py-2 px-4 rounded-[8px] max-sm:text-[14px] max-md:text-base text-[20px] font-medium max-md:py-2'}
            variant={'outlined'} color={'inherit'}
          >
            {t('requestAccess.backToHome')}
          </Button>
        </div>
        <Divider className={'w-full mb-3 mt-4'} />
        <div className={'max-w-[400px] flex flex-col text-text-caption'}>
          <span>
            <Trans
              i18nKey="approveAccess.ensurePlanLimit"
              components={{
                upgrade: <span
                  onClick={() => setUpgradeModalOpen(true)} className={'underline text-fill-default cursor-pointer'}
                >{t('approveAccess.upgrade')}</span>,
                download: <span
                  onClick={() => window.open(downloadPage, '_blank')}
                  className={'underline text-fill-default cursor-pointer'}
                >{t('approveAccess.downloadApp')}</span>,
              }}
            />
           </span>
        </div>
      </div>
      <NormalModal
        keepMounted={false}
        title={
          <div className={'text-left font-semibold'}>🎉{t('upgradePlanModal.title')}</div>
        } okText={t('upgradePlanModal.actionButton')} cancelText={t('upgradePlanModal.laterButton')}
        open={upgradeModalOpen}
        onClose={() => setUpgradeModalOpen(false)}
        onOk={handleUpgrade}
      >
        <div className="mt-2 py-3">
          <p className="text-sm text-text-caption">
            😄
            {t('upgradePlanModal.message')}
          </p>
        </div>
        <div className="mt-4 bg-gray-50 rounded-md p-4">
          <p className="text-sm font-medium text-text-caption">
            {t('upgradePlanModal.upgradeSteps')}
          </p>
          <ul className="mt-2 flex flex-col gap-1.5 list-disc list-inside text-sm text-text-caption">
            <li>{t('upgradePlanModal.step1')}</li>
            <li>{t('upgradePlanModal.step2')}</li>
            <li>{t('upgradePlanModal.step3')}</li>
          </ul>
        </div>
        <p className="mt-4 text-xs text-text-caption flex items-center gap-1">
          <WarningIcon className={'w-4 h-4 text-function-info'} />
          {t('upgradePlanModal.appNote')}{' '}
          <Trans
            i18nKey={'upgradePlanModal.refreshNote'} components={{
            refresh: <span
              className={'underline cursor-pointer text-fill-default'} onClick={() => window.location.reload()}
            >{t('upgradePlanModal.refresh')}</span>,
          }}
          />
        </p>

      </NormalModal>
      <NormalModal
        keepMounted={false}
        onOk={() => setErrorModalOpen(false)}
        title={
          <div className={'text-left font-semibold'}>{t('approveAccess.getRequestInfoError')}</div>
        } open={errorModalOpen} onClose={() => setErrorModalOpen(false)}
      >
        <div className={'flex flex-col'}>
           <span>
             <Trans
               i18nKey="requestAccess.tip"
               components={{
                 link: <span
                   className={'underline text-fill-default'}
                 >{requestInfo?.requester.name}</span>,
               }}
             />
           </span>
          <span>
            <Trans
              i18nKey="requestAccess.mightBe"
              components={{
                login: <span
                  onClick={() => openLoginModal?.()} className={'underline text-fill-default cursor-pointer'}
                >{t('signIn.logIn')}</span>,
              }}
            />
           </span>
        </div>
      </NormalModal>
      <NormalModal
        onOk={() => setAlreadyProModalOpen(false)}
        keepMounted={false}
        title={
          <div className={'text-left font-semibold gap-2 flex items-center'}>
            <WarningIcon className={'w-6 h-6 text-function-info'} />
            {t('approveAccess.alreadyProTitle')}
          </div>
        }
        open={alreadyProModalOpen}
        onClose={() => setAlreadyProModalOpen(false)}
      >
        <div className={'flex flex-col'}>
          <span>
            <Trans
              i18nKey={'approveAccess.alreadyProMessage'} components={{
              email: <span
                onClick={() => window.open(`mailto:support@appflowy.io`, '_blank')}
                className={'underline text-fill-default cursor-pointer'}
              >support@appflowy.io</span>,
            }}
            />
          </span>
        </div>
      </NormalModal>
    </div>

  );
}

export default ApproveRequestPage;