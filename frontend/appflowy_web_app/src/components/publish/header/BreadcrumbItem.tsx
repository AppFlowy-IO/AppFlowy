import { ViewLayout } from '@/application/collab.type';
import { usePublishContext } from '@/application/publish';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import React from 'react';
import { useTranslation } from 'react-i18next';

export interface Crumb {
  viewId: string;
  rowId?: string;
  name: string;
  icon: string;
  layout: ViewLayout;
}

function BreadcrumbItem({ crumb, disableClick = false }: { crumb: Crumb; disableClick?: boolean }) {
  const { viewId, icon, name, layout } = crumb;

  const { t } = useTranslation();
  const onNavigateToView = usePublishContext()?.toView;

  return (
    <div
      className={`flex items-center gap-1 text-sm ${!disableClick ? 'cursor-pointer' : 'flex-1 overflow-hidden'}`}
      onClick={async () => {
        if (disableClick) return;
        try {
          await onNavigateToView?.(viewId);
        } catch (e) {
          notify.default(t('publish.hasNotBeenPublished'));
        }
      }}
    >
      <span className={'icon'}>{icon || <ViewIcon layout={layout} size={'small'} />}</span>
      <span
        className={!disableClick ? 'max-w-[250px] truncate hover:text-text-title hover:underline' : 'flex-1 truncate'}
      >
        {name || t('menuAppHeader.defaultNewPageName')}
      </span>
    </div>
  );
}

export default BreadcrumbItem;
