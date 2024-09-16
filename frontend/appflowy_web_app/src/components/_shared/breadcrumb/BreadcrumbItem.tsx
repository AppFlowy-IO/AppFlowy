import { View } from '@/application/types';
import PublishIcon from '@/components/_shared/breadcrumb/PublishIcon';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import SpaceIcon from '@/components/_shared/breadcrumb/SpaceIcon';
import { renderColor } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import { Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function BreadcrumbItem ({ crumb, disableClick = false, toView, variant }: {
  crumb: View;
  disableClick?: boolean;
  toView?: (viewId: string) => Promise<void>;
  variant?: 'publish' | 'app'
}) {
  const { view_id, icon, name, layout, extra, is_published } = crumb;

  const { t } = useTranslation();
  const isFlag = useMemo(() => {
    return icon ? isFlagEmoji(icon.value) : false;
  }, [icon]);

  return (

    <div
      className={`flex items-center gap-1.5 text-sm ${!disableClick && is_published ? 'cursor-pointer' : 'flex-1 overflow-hidden'}`}
      onClick={async () => {
        if (disableClick || extra?.is_space || (!is_published && variant === 'publish')) return;
        try {
          await toView?.(view_id);
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
        } catch (e: any) {
          notify.error(e.message);
        }
      }}
    >
      {extra && extra.is_space ? (
        <span
          className={'icon h-4 w-4'}
          style={{
            backgroundColor: extra.space_icon_color ? renderColor(extra.space_icon_color) : 'rgb(163, 74, 253)',
            borderRadius: '4px',
          }}
        >
            <SpaceIcon value={extra.space_icon || ''} char={extra.space_icon ? undefined : name.slice(0, 1)} />
          </span>
      ) : (
        <span className={`${isFlag ? 'icon' : ''} flex h-5 w-5 items-center justify-center`}>
            {icon?.value || <ViewIcon layout={layout} size={'small'} />}
          </span>
      )}
      <Tooltip title={name} placement={'bottom'} enterDelay={1000} enterNextDelay={1000}>
        <span
          className={
            'max-w-[250px] overflow-hidden truncate ' +
            (!disableClick && is_published ? 'hover:text-text-title hover:underline' : 'flex-1')
          }
        >
          {name || t('menuAppHeader.defaultNewPageName')}
        </span>
      </Tooltip>
      <PublishIcon variant={variant} crumb={crumb} />
    </div>
  );
}

export default BreadcrumbItem;
