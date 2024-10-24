import { UIVariant, View, ViewLayout } from '@/application/types';
import SpaceIcon from '@/components/_shared/breadcrumb/SpaceIcon';
import { ViewIcon } from '@/components/_shared/view-icon';
import PublishIcon from '@/components/_shared/view-icon/PublishIcon';
import { renderColor } from '@/utils/color';
import { isFlagEmoji } from '@/utils/emoji';
import { Tooltip } from '@mui/material';
import React, { memo } from 'react';

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
  variant?: UIVariant;

}) {
  const { icon, layout, name, view_id, extra } = item;
  const [hovered, setHovered] = React.useState(false);
  const isSpace = extra?.is_space;

  return (
    <div
      onClick={async () => {
        if (isSpace || (!item.is_published && variant === 'publish') || item.layout === ViewLayout.AIChat) {
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
        cursor: item.layout === ViewLayout.AIChat ? 'not-allowed' : 'pointer',
        paddingLeft: variant === 'favorite' || variant === 'recent' ? '8px' : item.children?.length ? 0 : 1.125 * (level + 1) + 'em',
      }}
      className={`flex flex-1 select-none items-center gap-1.5 overflow-hidden`}
    >
      {isSpace && extra ?
        <span
          className={'icon h-[1.2em] w-[1.2em]'}
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
          {icon?.value || <ViewIcon
            layout={layout}
            size={'medium'}
          />}
        </div>
      }

      <Tooltip
        title={name}
        enterDelay={1000}
        enterNextDelay={1000}
      >
        <div className={'flex-1 truncate'}>{name}</div>
      </Tooltip>
      {hovered && variant === UIVariant.Publish && <PublishIcon
        variant={variant}
        view={item}
      />}
    </div>
  );
}

export default memo(OutlineItemContent);