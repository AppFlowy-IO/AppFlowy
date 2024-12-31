import React, { useCallback, useEffect, useMemo } from 'react';
import { NormalModal } from '@/components/_shared/modal';
import { useTranslation } from 'react-i18next';
import { Subscription, SubscriptionInterval, SubscriptionPlan } from '@/application/types';
import { useAppHandlers, useCurrentWorkspaceId } from '@/components/app/app.hooks';
import { ViewTabs, ViewTab } from '@/components/_shared/tabs/ViewTabs';
import { Button } from '@mui/material';
import { notify } from '@/components/_shared/notify';
import { useService } from '@/components/main/app.hooks';
import CancelSubscribe from '@/components/billing/CancelSubscribe';
import { useSearchParams } from 'react-router-dom';

function UpgradePlan({ open, onClose, onOpen }: {
  open: boolean;
  onClose: () => void;
  onOpen: () => void;
}) {
  const { t } = useTranslation();
  const [activeSubscription, setActiveSubscription] = React.useState<Subscription | null>(null);
  const service = useService();
  const currentWorkspaceId = useCurrentWorkspaceId();
  const [cancelOpen, setCancelOpen] = React.useState(false);
  const { getSubscriptions } = useAppHandlers();

  const [search, setSearch] = useSearchParams();
  const action = search.get('action');

  useEffect(() => {
    if (!open && action === 'change_plan') {
      onOpen();
    }

    if (open) {
      setSearch(prev => {
        prev.set('action', 'change_plan');
        return prev;
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [action, open, setSearch]);

  const loadSubscription = useCallback(async () => {
    try {
      const subscriptions = await getSubscriptions?.();

      if (!subscriptions || subscriptions.length === 0) {
        setActiveSubscription({
          plan: SubscriptionPlan.Free,
          currency: '',
          recurring_interval: SubscriptionInterval.Month,
          price_cents: 0,
        });
        return;
      }

      const subscription = subscriptions[0];

      setActiveSubscription(subscription);
    } catch (e) {
      console.error(e);
    }
  }, [getSubscriptions]);

  const handleClose = useCallback(() => {
    onClose();
    setSearch(prev => {
      prev.delete('action');
      return prev;
    });
  }, [onClose, setSearch]);
  const [interval, setInterval] = React.useState<SubscriptionInterval>(SubscriptionInterval.Year);

  const handleUpgrade = useCallback(async () => {
    if (!service || !currentWorkspaceId) return;
    const plan = SubscriptionPlan.Pro;

    try {
      const link = await service.getSubscriptionLink(currentWorkspaceId, plan, interval);

      window.open(link, '_current');
      // eslint-disable-next-line
    } catch (e: any) {
      notify.error(e.message);
    }
  }, [currentWorkspaceId, service, interval]);

  useEffect(() => {
    if (open) {
      void loadSubscription();
    }
  }, [open, loadSubscription]);

  const plans = useMemo(() => {
    return [{
      key: SubscriptionPlan.Free,
      name: t('subscribe.free'),
      price: 'Free',
      description: t('subscribe.freeDescription'),
      duration: t('subscribe.freeDuration'),
      points: [
        t('subscribe.freePoints.first'),
        t('subscribe.freePoints.second'),
        t('subscribe.freePoints.three'),
        t('subscribe.freePoints.four'),
        t('subscribe.freePoints.five'),
        t('subscribe.freePoints.six'),
        t('subscribe.freePoints.seven'),
      ],
    }, {
      key: SubscriptionPlan.Pro,
      name: t('subscribe.pro'),
      price: interval === SubscriptionInterval.Month ? '$12.5' : '$10',
      description: t('subscribe.proDescription'),
      duration: interval === SubscriptionInterval.Month ? t('subscribe.proDuration.monthly') : t('subscribe.proDuration.yearly'),
      points: [
        t('subscribe.proPoints.first'),
        t('subscribe.proPoints.second'),
        t('subscribe.proPoints.three'),
        t('subscribe.proPoints.four'),
        t('subscribe.proPoints.five'),
      ],
    }];
  }, [t, interval]);

  return (
    <NormalModal
      open={open}
      onClose={handleClose}
      title={t('subscribe.upgradePlanTitle')}
      disableRestoreFocus={true}
      cancelButtonProps={{
        className: 'hidden',
      }}
      okButtonProps={{
        className: 'hidden',
      }}
      slotProps={{
        root: {
          className: 'min-w-[500px] max-w-full max-h-full',
        },
      }}
    >
      <div className={'flex flex-col gap-4 p-4 w-full'}>
        <div className={'flex justify-between gap-4 items-center'}>
          <ViewTabs indicatorColor={'secondary'} value={interval} onChange={(_, v) => {
            setInterval(v);
          }}>
            <ViewTab label={`${t('subscribe.yearly')} ${t('subscribe.save', {
              discount: 20,
            })}`} value={SubscriptionInterval.Year}/>
            <ViewTab label={t('subscribe.monthly')} value={SubscriptionInterval.Month}/>
          </ViewTabs>
          <div className={'flex items-center justify-end'}>
            {t('subscribe.priceIn')}
            <span className={'font-medium ml-1.5'}>{`$USD`}</span>
          </div>
        </div>

        <div className={'flex gap-4 w-full overflow-auto'}>
          {plans.map((plan) => {
            return <div key={plan.key} style={{
              borderColor: activeSubscription?.plan === plan.key ? 'var(--billing-primary)' : undefined,
            }} className={'relative flex flex-col gap-2 p-4 border rounded-[16px] border-line-divider'}>
              {activeSubscription?.plan === plan.key &&
                <div
                  className={'absolute bg-billing-primary text-content-on-fill right-0 top-0 rounded-[14px] text-xs rounded-br-none rounded-tl-none p-2'}>
                  {t('subscribe.currentPlan')}
                </div>}
              <div className={'font-medium'}>{plan.name}</div>
              <div className={'text-text-caption text-sm'}>{plan.description}</div>
              <div
                className={'text-lg'}>{plan.price}
              </div>
              <div className={'text-text-caption whitespace-pre-wrap'}>{plan.duration}</div>

              {plan.key === SubscriptionPlan.Pro ?
                <div className={'flex flex-col gap-2'}>
                  {activeSubscription?.plan !== plan.key &&
                    <Button
                      color={'secondary'}
                      onClick={handleUpgrade}
                      variant={'contained'}>
                      {t('subscribe.changePlan')}
                    </Button>}
                  <span className={'font-medium'}>{t('subscribe.everythingInFree')}</span>
                </div> :
                activeSubscription?.plan !== plan.key &&
                <Button onClick={() => {
                  setCancelOpen(true);
                }} variant={'outlined'} color={'inherit'}>
                  {t('subscribe.cancel')}
                </Button>
              }
              <div className={'flex flex-col gap-2'}>
                {plan.points.map((point, index) => {
                  return <div key={index} className={'flex gap-2 items-start'}>
                    <div className={'flex h-6 items-center'}>
                      <div className={'w-2 h-2 rounded-full bg-billing-primary'}/>
                    </div>
                    <div className={''}>{point}</div>
                  </div>;
                })}
              </div>
            </div>;
          })}
        </div>
      </div>
      <CancelSubscribe onCanceled={loadSubscription} open={cancelOpen} onClose={() => {
        setCancelOpen(false);
      }}/>
    </NormalModal>
  );
}

export default UpgradePlan;