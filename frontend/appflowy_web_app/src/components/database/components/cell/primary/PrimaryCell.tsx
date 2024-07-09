import { useNavigateToRow, useRowMetaSelector } from '@/application/database-yjs';
import { TextCell as CellType, CellProps } from '@/application/database-yjs/cell.type';
import { TextCell } from '@/components/database/components/cell/text';
import { getPlatform } from '@/utils/platform';
import React, { useEffect, useMemo, useState } from 'react';

export function PrimaryCell(props: CellProps<CellType>) {
  const { rowId } = props;
  const meta = useRowMetaSelector(rowId);
  const icon = meta?.icon;

  const [, setHover] = useState(false);

  useEffect(() => {
    const table = document.querySelector('.grid-table');

    if (!table) {
      return;
    }

    const onMouseMove = (e: Event) => {
      const target = e.target as HTMLElement;

      if (target.closest('.grid-row-cell')?.getAttribute('data-row-id') === rowId) {
        setHover(true);
      } else {
        setHover(false);
      }
    };

    const onMouseLeave = () => {
      setHover(false);
    };

    table.addEventListener('mousemove', onMouseMove);
    table.addEventListener('mouseleave', onMouseLeave);
    return () => {
      table.removeEventListener('mousemove', onMouseMove);
      table.removeEventListener('mouseleave', onMouseLeave);
    };
  }, [rowId]);

  const isMobile = useMemo(() => {
    return getPlatform().isMobile;
  }, []);

  const navigateToRow = useNavigateToRow();

  return (
    <div
      onClick={() => {
        if (isMobile) {
          navigateToRow?.(rowId);
        }
      }}
      className={'primary-cell relative flex min-h-full w-full items-center gap-2'}
    >
      {icon && <div className={'h-4 w-4'}>{icon}</div>}
      <div className={'flex-1 overflow-x-hidden'}>
        <TextCell {...props} />
      </div>

      {/*{hover && (*/}
      {/*  <div className={'absolute right-0 top-1/2 min-w-0 -translate-y-1/2 transform '}>*/}
      {/*    <OpenAction rowId={rowId} />*/}
      {/*  </div>*/}
      {/*)}*/}
    </div>
  );
}

export default PrimaryCell;
