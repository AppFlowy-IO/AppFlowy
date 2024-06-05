import { useSortsSelector } from '@/application/database-yjs';
import { Popover } from '@/components/_shared/popover';
import SortList from '@/components/database/components/sorts/SortList';
import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ReactComponent as SortSvg } from '$icons/16x/sort_ascending.svg';
import { ReactComponent as ArrowDownSvg } from '$icons/16x/arrow_down.svg';

export function Sorts() {
  const { t } = useTranslation();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);
  const sorts = useSortsSelector();

  if (sorts.length === 0) return null;
  return (
    <>
      <div
        onClick={(e) => {
          setAnchorEl(e.currentTarget);
        }}
        className='flex cursor-pointer items-center gap-1 rounded-full border border-line-divider px-2 py-1 text-xs hover:border-fill-default hover:text-fill-default hover:shadow-sm'
      >
        <SortSvg />
        {t('grid.settings.sort')}
        <ArrowDownSvg />
      </div>
      {open && (
        <Popover
          open={open}
          anchorEl={anchorEl}
          onClose={() => {
            setAnchorEl(null);
          }}
        >
          <SortList />
        </Popover>
      )}
    </>
  );
}

export default Sorts;
