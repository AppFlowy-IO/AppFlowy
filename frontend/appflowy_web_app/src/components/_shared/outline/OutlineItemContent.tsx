import { UIVariant, View, ViewLayout } from '@/application/types';
import SpaceIcon from '@/components/_shared/view-icon/SpaceIcon';
import PublishIcon from '@/components/_shared/view-icon/PublishIcon';
import { Tooltip } from '@mui/material';
import React, { memo } from 'react';
import { useTranslation } from 'react-i18next';
import PageIcon from '@/components/_shared/view-icon/PageIcon';

function OutlineItemContent({
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
  const { name, view_id, extra } = item;
  const [hovered, setHovered] = React.useState(false);
  const isSpace = extra?.is_space;
  const { t } = useTranslation();

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
        <SpaceIcon
          bgColor={extra.space_icon_color}
          value={extra.space_icon || ''}
          char={extra.space_icon ? undefined : name.slice(0, 1)}
        /> :
        <PageIcon view={item} className={'flex h-5 w-5 min-w-5 items-center justify-center'}/>
      }

      <Tooltip
        title={name}
        enterDelay={1000}
        enterNextDelay={1000}
      >
        <div className={'flex-1 truncate'}>{name || t('menuAppHeader.defaultNewPageName')}</div>
      </Tooltip>
      {hovered && variant === UIVariant.Publish && <PublishIcon
        variant={variant}
        view={item}
      />}
    </div>
  );
}

export default memo(OutlineItemContent);