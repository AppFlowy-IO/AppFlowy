import { ViewLayout } from '@/application/collab.type';
import { usePublishContext } from '@/application/publish';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import SpaceIcon from '@/components/publish/header/SpaceIcon';
import { renderColor } from '@/utils/color';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

export interface Crumb {
  viewId: string;
  rowId?: string;
  name: string;
  icon: string;
  layout: ViewLayout;
  extra?: string | null;
}

function BreadcrumbItem({ crumb, disableClick = false }: { crumb: Crumb; disableClick?: boolean }) {
  const { viewId, icon, name, layout, extra } = crumb;

  const extraObj: {
    is_space?: boolean;
    space_icon?: string;
    space_icon_color?: string;
  } = useMemo(() => {
    try {
      return extra ? JSON.parse(extra) : {};
    } catch (e) {
      return {};
    }
  }, [extra]);

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
      {extraObj && extraObj.is_space ? (
        <span
          className={'icon h-5 w-5'}
          style={{
            backgroundColor: extraObj.space_icon_color ? renderColor(extraObj.space_icon_color) : undefined,
            borderRadius: '8px',
          }}
        >
          <SpaceIcon value={extraObj.space_icon || ''} />
        </span>
      ) : (
        <span className={'icon flex h-5 w-5 items-center justify-center'}>
          {icon || <ViewIcon layout={layout} size={'small'} />}
        </span>
      )}

      <span
        className={!disableClick ? 'max-w-[250px] truncate hover:text-text-title hover:underline' : 'flex-1 truncate'}
      >
        {name || t('menuAppHeader.defaultNewPageName')}
      </span>
    </div>
  );
}

export default BreadcrumbItem;
