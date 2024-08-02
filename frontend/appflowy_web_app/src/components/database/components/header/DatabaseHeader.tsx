import { ViewLayout, ViewMetaIcon } from '@/application/collab.type';
import { ViewIcon } from '@/components/_shared/view-icon';
import { isFlagEmoji } from '@/utils/emoji';
import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';

function DatabaseHeader({
  icon,
  name,
  layout,
}: {
  icon?: ViewMetaIcon;
  name?: string;
  viewId?: string;
  layout?: ViewLayout;
}) {
  const { t } = useTranslation();
  const isFlag = useMemo(() => {
    return icon ? isFlagEmoji(icon.value) : false;
  }, [icon]);

  return (
    <div
      className={
        'my-10 flex w-full items-center gap-4 whitespace-pre-wrap break-words break-all text-[2.25rem] font-bold leading-[1.5em] max-sm:text-[7vw]'
      }
    >
      <div className={'relative'}>
        {icon?.value ? (
          <div className={`view-icon ${isFlag ? 'icon' : ''}`}>{icon?.value}</div>
        ) : (
          <ViewIcon layout={layout || ViewLayout.Grid} size={10} />
        )}
      </div>
      <div className={'relative'}>
        {name || <span className={'text-text-placeholder'}>{t('menuAppHeader.defaultNewPageName')}</span>}
      </div>
    </div>
  );
}

export default DatabaseHeader;
