import { ViewLayout } from '@/application/collab.type';
import { usePublishContext } from '@/application/publish';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import SpaceIcon from '@/components/publish/header/SpaceIcon';
import { renderColor } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import { Tooltip } from '@mui/material';
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

function BreadcrumbItem ({ crumb, disableClick = false }: { crumb: Crumb; disableClick?: boolean }) {
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
  const isFlag = useMemo(() => {
    return icon ? isFlagEmoji(icon) : false;
  }, [icon]);

  return (
    <Tooltip title={name} placement={'bottom'} enterDelay={1000} enterNextDelay={1000}>
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
              backgroundColor: extraObj.space_icon_color ? renderColor(extraObj.space_icon_color) : 'rgb(163, 74, 253)',
              borderRadius: '8px',
            }}
          >
            <SpaceIcon value={extraObj.space_icon || ''} char={extraObj.space_icon ? undefined : name.slice(0, 1)} />
          </span>
        ) : (
          <span className={`${isFlag ? 'icon' : ''} flex h-5 w-5 items-center justify-center`}>
            {icon || <ViewIcon layout={layout} size={'small'} />}
          </span>
        )}

        <span
          className={
            'max-w-[250px] overflow-hidden truncate ' +
            (!disableClick ? 'hover:text-text-title hover:underline' : 'flex-1')
          }
        >
          {name || t('menuAppHeader.defaultNewPageName')}
        </span>
      </div>
    </Tooltip>
  );
}

export default BreadcrumbItem;
