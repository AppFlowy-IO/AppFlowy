import { View } from '@/application/types';
import BreadcrumbItem from '@/components/_shared/breadcrumb/BreadcrumbItem';
import { NormalModal } from '@/components/_shared/modal';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function BreadcrumbMoreModal ({ open, onClose, crumbs, toView }: {
  open: boolean;
  onClose: () => void;
  crumbs: View[];
  toView?: (viewId: string) => Promise<void>;
}) {
  const { t } = useTranslation();
  const title = useMemo(() => {
    return <div className={'flex items-center gap-2'}>
      <div className={'flex-1 font-semibold text-center'}>{t('breadcrumbs.label')}</div>
    </div>;
  }, [t]);

  return (
    <NormalModal
      title={title}
      okButtonProps={{
        className: 'hidden',
      }}
      cancelButtonProps={{
        className: 'hidden',
      }}
      open={open}
      onClose={onClose}
    >
      <div className={'flex flex-col justify-start gap-2 min-w-[350px] max-sm:min-w-full'}>
        {crumbs.map((crumb, index) => (
          <div
            key={crumb.view_id}
            onClick={() => {
              if (index === 0) return;
              onClose();
            }}
            className={`flex items-center gap-2 ${index !== 0 ? 'hover:bg-fill-list-hover cursor-pointer' : ''} rounded-[8px] py-1.5`}
            style={{
              paddingLeft: (index + 1) * 16,
            }}
          >
            {index !== 0 && <div className={'text-text-caption'}> {'-'} </div>}
            <BreadcrumbItem
              crumb={crumb}
              toView={toView}
            />
          </div>
        ))}
      </div>
    </NormalModal>
  );
}

export default BreadcrumbMoreModal;