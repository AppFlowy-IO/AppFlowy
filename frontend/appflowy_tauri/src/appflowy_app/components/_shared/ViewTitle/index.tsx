import React, { useCallback, useEffect, useState } from 'react';
import ViewBanner from '$app/components/_shared/ViewTitle/ViewBanner';
import { Page, PageIcon } from '$app_reducers/pages/slice';
import { ViewIconTypePB } from '@/services/backend';
import ViewTitleInput from '$app/components/_shared/ViewTitle/ViewTitleInput';

interface Props {
  view: Page;
  showTitle?: boolean;
  onTitleChange?: (title: string) => void;
  onUpdateIcon?: (icon: PageIcon) => void;
}

function ViewTitle({ view, onTitleChange, showTitle = true, onUpdateIcon: onUpdateIconProp }: Props) {
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
      <ViewBanner icon={icon} hover={hover} onUpdateIcon={onUpdateIcon} />
      {showTitle && (
        <div className='relative'>
          <ViewTitleInput value={view.name} onChange={onTitleChange} />
        </div>
      )}
    </div>
  );
}

export default ViewTitle;
