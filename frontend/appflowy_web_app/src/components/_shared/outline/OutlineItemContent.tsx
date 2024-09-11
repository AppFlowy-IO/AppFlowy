import { View } from '@/application/types';
import SpaceIcon from '@/components/_shared/breadcrumb/SpaceIcon';
import { ViewIcon } from '@/components/_shared/view-icon';
import { renderColor } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import { Tooltip } from '@mui/material';
import React, { memo } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as PublishIcon } from '@/assets/publish.svg';

function OutlineItemContent ({
  item,
  setIsExpanded,
  navigateToView,
  level,
  variant,
}: {
  item: View;
  setIsExpanded: React.Dispatch<React.SetStateAction<boolean>>;
  navigateToView?: (viewId: string) => Promise<void>;
  level: number;
  variant?: 'publish' | 'app' | 'recent' | 'favorite';

}) {
  const { icon, layout, name, view_id, extra } = item;
  const [hovered, setHovered] = React.useState(false);
  const isSpace = extra?.is_space;
  const { t } = useTranslation();

  return (
    <div
      onClick={async () => {
        if (isSpace || (!item.is_published && variant === 'publish')) {
          setIsExpanded(prev => !prev);
          return;
        }

        try {
          await navigateToView?.(view_id);
        } catch (e) {
          // do nothing
        }
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        paddingLeft: variant === 'favorite' || variant === 'recent' ? '8px' : item.children?.length ? 0 : 1.125 * (level + 1) + 'rem',
      }}
      className={`flex flex-1 cursor-pointer select-none items-center gap-1.5 overflow-hidden`}
    >
      {isSpace && extra ?
        <span
          className={'icon h-4 w-4'}
          style={{
            backgroundColor: extra.space_icon_color ? renderColor(extra.space_icon_color) : 'rgb(163, 74, 253)',
            borderRadius: '4px',
          }}
        >
          <SpaceIcon
            value={extra.space_icon || ''}
            char={extra.space_icon ? undefined : name.slice(0, 1)}
          />
        </span> :
        <div
          className={`${icon && isFlagEmoji(icon.value) ? 'icon' : ''}`}
        >
          {icon?.value || <ViewIcon layout={layout} size={'medium'} />}
        </div>
      }

      <Tooltip title={name} enterDelay={1000} enterNextDelay={1000}>
        <div className={'flex-1 truncate'}>{name}</div>
      </Tooltip>
      {hovered && variant === 'publish' && !item.is_published && !isSpace && (
        <Tooltip
          disableInteractive
          title={isSpace ? t('publish.spaceHasNotBeenPublished') : t('publish.hasNotBeenPublished')}
        >
          <div
            className={'text-text-caption ml-2 mr-4 cursor-pointer hover:bg-fill-list-hover rounded h-5 w-5 flex items-center justify-center'}
          >
            <PublishIcon className={'h-4 w-4'} />
          </div>
        </Tooltip>
      )}
    </div>
  );
}

export default memo(OutlineItemContent);