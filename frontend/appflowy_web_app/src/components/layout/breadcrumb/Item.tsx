import { Crumb, useNavigateToView } from '@/application/folder-yjs';
import React from 'react';
import { useTranslation } from 'react-i18next';

function Item({ crumb, disableClick = false }: { crumb: Crumb; disableClick?: boolean }) {
  const { viewId, icon, name } = crumb;

  const { t } = useTranslation();
  const onNavigateToView = useNavigateToView();

  return (
    <div
      className={`flex items-center gap-1 ${!disableClick ? 'cursor-pointer' : 'flex-1 overflow-hidden'}`}
      onClick={() => {
        if (disableClick) return;
        onNavigateToView?.(viewId);
      }}
    >
      {icon}
      <span className={!disableClick ? 'underline' : 'flex-1 truncate'}>
        {name || t('menuAppHeader.defaultNewPageName')}
      </span>
    </div>
  );
}

export default Item;
