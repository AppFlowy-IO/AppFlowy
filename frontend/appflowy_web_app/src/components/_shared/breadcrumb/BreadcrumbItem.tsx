import { UIVariant, View } from '@/application/types';
import PublishIcon from '@/components/_shared/view-icon/PublishIcon';
import { notify } from '@/components/_shared/notify';
import SpaceIcon from '@/components/_shared/view-icon/SpaceIcon';
import { Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import PageIcon from '@/components/_shared/view-icon/PageIcon';

function BreadcrumbItem({ crumb, disableClick = false, toView, variant }: {
  crumb: View;
  disableClick?: boolean;
  toView?: (viewId: string) => Promise<void>;
  variant?: UIVariant
}) {
  const { view_id, name, extra, is_published } = crumb;

  const { t } = useTranslation();

  const className = useMemo(() => {
    const classList = ['flex', 'items-center', 'gap-1.5', 'text-sm', 'overflow-hidden', 'max-sm:text-base'];

    if (!disableClick && !extra?.is_space) {
      if ((is_published && variant === 'publish') || variant === 'app') {
        classList.push('cursor-pointer hover:text-text-title hover:underline');
      } else {
        classList.push('flex-1');
      }
    }

    return classList.join(' ');
  }, [disableClick, extra?.is_space, is_published, variant]);

  return (

    <div
      className={className}
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
        <SpaceIcon
          className={'icon h-4 w-4 shrink-0'}
          bgColor={extra.space_icon_color}
          value={extra.space_icon || ''}
          char={extra.space_icon ? undefined : name.slice(0, 1)}
        />
      ) : (
        <PageIcon view={crumb} className={'flex h-5 w-5 min-w-5 items-center justify-center'}/>
      )}
      <Tooltip
        title={name}
        placement={'bottom'}
        enterDelay={1000}
        enterNextDelay={1000}
      >
        <span
          className={
            'max-w-[250px] min-w-[2.5rem] flex-1 overflow-hidden truncate '
          }
        >
          {name || t('menuAppHeader.defaultNewPageName')}
        </span>
      </Tooltip>
      <PublishIcon
        variant={variant}
        view={crumb}
      />
    </div>
  );
}

export default BreadcrumbItem;
