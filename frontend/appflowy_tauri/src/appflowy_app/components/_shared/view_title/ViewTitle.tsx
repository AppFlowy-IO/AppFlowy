import React, { useCallback, useEffect, useState } from 'react';
import ViewBanner from '$app/components/_shared/view_title/ViewBanner';
import { Page, PageCover, PageIcon } from '$app_reducers/pages/slice';
import { ViewIconTypePB } from '@/services/backend';
import ViewTitleInput from '$app/components/_shared/view_title/ViewTitleInput';

interface Props {
  view: Page;
  showTitle?: boolean;
  onTitleChange?: (title: string) => void;
  onUpdateIcon?: (icon: PageIcon) => void;
  forceHover?: boolean;
  showCover?: boolean;
  onUpdateCover?: (cover?: PageCover) => void;
}

function ViewTitle({
  view,
  forceHover = false,
  onTitleChange,
  showTitle = true,
  onUpdateIcon: onUpdateIconProp,
  showCover = false,
  onUpdateCover,
}: Props) {
  const [hover, setHover] = useState(false);
  const [icon, setIcon] = useState<PageIcon | undefined>(view.icon);

  useEffect(() => {
    setIcon(view.icon);
  }, [view.icon]);

  const onUpdateIcon = useCallback(
    (icon: string) => {
      const newIcon = {
        value: icon,
        ty: ViewIconTypePB.Emoji,
      };

      setIcon(newIcon);
      onUpdateIconProp?.(newIcon);
    },
    [onUpdateIconProp]
  );

  return (
    <div
      className={'flex flex-col justify-end'}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
    >
      <ViewBanner
        showCover={showCover}
        cover={view.cover}
        icon={icon}
        hover={hover || forceHover}
        onUpdateIcon={onUpdateIcon}
        onUpdateCover={onUpdateCover}
      />
      {showTitle && (
        <div className='relative'>
          <ViewTitleInput value={view.name} onChange={onTitleChange} />
        </div>
      )}
    </div>
  );
}

export default ViewTitle;
