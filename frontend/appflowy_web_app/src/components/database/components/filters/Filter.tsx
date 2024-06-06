import { useFilterSelector } from '@/application/database-yjs';
import { Popover } from '@/components/_shared/popover';
import { FilterContentOverview } from './overview';
import React, { useState } from 'react';
import { FieldDisplay } from '@/components/database/components/field';
import { ReactComponent as ArrowDownSvg } from '$icons/16x/arrow_down.svg';
import { FilterMenu } from './filter-menu';

function Filter({ filterId }: { filterId: string }) {
  const filter = useFilterSelector(filterId);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  if (!filter) return null;

  return (
    <>
      <div
        onClick={(e) => {
          setAnchorEl(e.currentTarget);
        }}
        data-testid={'database-filter-condition'}
        className={
          'flex cursor-pointer flex-nowrap items-center gap-1 rounded-full border border-line-divider py-1 px-2 hover:border-fill-default hover:text-fill-default hover:shadow-sm'
        }
      >
        <div className={'max-w-[180px] overflow-hidden'}>
          <FieldDisplay fieldId={filter.fieldId} />
        </div>

        <div className={'whitespace-nowrap text-xs font-medium'}>
          <FilterContentOverview filter={filter} />
        </div>
        <ArrowDownSvg />
      </div>
      {open && (
        <Popover
          open={open}
          anchorEl={anchorEl}
          onClose={() => {
            setAnchorEl(null);
          }}
          data-testid={'filter-menu-popover'}
          slotProps={{
            paper: {
              style: {
                maxHeight: '260px',
              },
            },
          }}
        >
          <FilterMenu filter={filter} />
        </Popover>
      )}
    </>
  );
}

export default Filter;
