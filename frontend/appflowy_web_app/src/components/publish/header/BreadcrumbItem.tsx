import { ReactComponent as PublishIcon } from '@/assets/publish.svg';
import { usePublishContext } from '@/application/publish';
import { View } from '@/application/types';
import { notify } from '@/components/_shared/notify';
import { ViewIcon } from '@/components/_shared/view-icon';
import SpaceIcon from '@/components/publish/header/SpaceIcon';
import { renderColor } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import { Tooltip } from '@mui/material';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function BreadcrumbItem ({ crumb, disableClick = false }: { crumb: View; disableClick?: boolean }) {
  const { view_id, icon, name, layout, extra, is_published } = crumb;

  const { t } = useTranslation();
  const onNavigateToView = usePublishContext()?.toView;
  const isFlag = useMemo(() => {
    return icon ? isFlagEmoji(icon.value) : false;
  }, [icon]);

  return (

    <div
      className={`flex items-center gap-1.5 text-sm ${!disableClick && is_published ? 'cursor-pointer' : 'flex-1 overflow-hidden'}`}
      onClick={async () => {
        if (disableClick || !is_published) return;
        try {
          await onNavigateToView?.(view_id);
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
      {!is_published && !extra?.is_space && (<Tooltip
        disableInteractive
        title={extra?.is_space ? t('publish.spaceHasNotBeenPublished') : t('publish.hasNotBeenPublished')}
      >
        <div
          className={'text-text-caption cursor-pointer hover:bg-fill-list-hover rounded h-5 w-5 flex items-center justify-center'}
        >
          <PublishIcon className={'h-4 w-4'} />
        </div>
      </Tooltip>)}

    </div>
  );
}

export default BreadcrumbItem;
