import {
  GetRequestAccessInfoResponse,
  RequestAccessInfoStatus,
  SubscriptionInterval,
  SubscriptionPlan,
} from '@/application/types';
import { ReactComponent as AppflowyLogo } from '@/assets/appflowy.svg';
import { ReactComponent as WarningIcon } from '@/assets/warning.svg';
import { NormalModal } from '@/components/_shared/modal';
import ChangeAccount from '@/components/_shared/modal/ChangeAccount';
import { notify } from '@/components/_shared/notify';
import { getAvatar } from '@/components/_shared/view-icon/utils';
import { AFConfigContext, useService } from '@/components/main/app.hooks';

import { Avatar, Button } from '@mui/material';
import React, { useCallback, useContext, useEffect, useMemo } from 'react';
import { Trans, useTranslation } from 'react-i18next';
import { useNavigate, useSearchParams } from 'react-router-dom';

const WorkspaceMemberLimitExceededCode = 1027;
const REPEAT_REQUEST_CODE = 1043;

function ApproveRequestPage () {
  const [searchParams] = useSearchParams();
  const isAuthenticated = useContext(AFConfigContext)?.isAuthenticated;

  const [requestInfo, setRequestInfo] = React.useState<GetRequestAccessInfoResponse | null>(null);
  const [currentPlans, setCurrentPlans] = React.useState<SubscriptionPlan[]>([]);
  const isPro = useMemo(() => currentPlans.includes(SubscriptionPlan.Pro), [currentPlans]);
  const requestId = searchParams.get('request_id');
  const service = useService();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [upgradeModalOpen, setUpgradeModalOpen] = React.useState(true);
  const [errorModalOpen, setErrorModalOpen] = React.useState(false);
  const [alreadyProModalOpen, setAlreadyProModalOpen] = React.useState(false);
  const [clicked, setClicked] = React.useState(false);

  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login?redirectTo=' + encodeURIComponent(window.location.href));
    }
  }, [isAuthenticated, navigate]);
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
    <div
      className={'text-text-title px-6 max-md:gap-4 flex flex-col gap-12 h-screen appflowy-scroller w-screen overflow-x-hidden overflow-y-auto items-center bg-bg-body'}
    >
      <div
        onClick={() => {
          navigate('/app');
        }}
        className={'flex w-full cursor-pointer max-md:justify-center max-md:h-32 h-20 items-center justify-between sticky'}
      >
        <AppflowyLogo className={'w-32 h-12 max-md:w-52'} />
      </div>
      <div className={'flex w-full flex-1 max-w-[560px] justify-center flex-col items-center gap-6 text-center'}>
        <Avatar
          className={'h-20 w-20 text-[40px] border border-text-title rounded-[16px]'} {...requesterAvatar}
          variant="rounded"
        />
        <div
          className={'text-[40px] max-sm:text-[24px] px-4 whitespace-pre-wrap break-words leading-[127%] text-center'}
        >
          <span className={'font-semibold'}>{requestInfo?.requester?.email}</span>
          {' '}
          {t('approveAccess.requestToJoin')}
          {' '}
          <span className={'whitespace-nowrap font-semibold'}>{requestInfo?.workspace?.name}</span>
          {' '}
          {t('approveAccess.asMember')}
        </div>

        <div className={'flex mb-52 items-center mt-4 w-full gap-4 justify-between'}>
          <Button
            onClick={() => {
              void handleApprove();
              setClicked(true);
            }}
            disabled={clicked || !requestInfo}
            className={'flex-1 py-2 px-4 rounded-[8px] text-[20px] font-medium max-md:text-base max-sm:text-[14px] max-md:py-2'}
            variant={'contained'}
            color={'primary'}
          >
            {t('approveAccess.approveButton')}
          </Button>
          <Button
            onClick={() => {
              navigate('/');
            }}
            className={'flex-1 py-2 px-4 rounded-[8px] max-sm:text-[14px] max-md:text-base text-[20px] font-medium max-md:py-2'}
            variant={'outlined'}
            color={'inherit'}
          >
            {t('requestAccess.backToHome')}
          </Button>
        </div>

      </div>
      <NormalModal
        keepMounted={false}
        title={
          <div className={'text-left font-semibold'}>{t('upgradePlanModal.title')}</div>
        }
        okText={t('upgradePlanModal.actionButton')}
        cancelText={t('upgradePlanModal.laterButton')}
        open={upgradeModalOpen}
        onClose={() => setUpgradeModalOpen(false)}
        onOk={handleUpgrade}
      >
        <div className="py-3">
          <p className="text-base text-text-caption">
            {t('upgradePlanModal.message', {
              name: requestInfo?.workspace.name,
            })}
          </p>
        </div>
      </NormalModal>
      <ChangeAccount
        setModalOpened={setErrorModalOpen}
        modalOpened={errorModalOpen}
      />
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
              i18nKey={'approveAccess.alreadyProMessage'}
              components={{
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