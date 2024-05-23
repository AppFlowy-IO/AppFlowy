import { useReadOnly } from '@/application/database-yjs';
import { CellProps, UrlCell as UrlCellType } from '@/components/database/components/cell/cell.type';
import { openUrl, processUrl } from '@/utils/url';
import React, { useMemo } from 'react';

export function UrlCell({ cell, style, placeholder }: CellProps<UrlCellType>) {
  const readOnly = useReadOnly();

  const isUrl = useMemo(() => (cell ? processUrl(cell.data) : false), [cell]);

  const className = useMemo(() => {
    const classList = ['select-text', 'w-fit'];

    if (isUrl) {
      classList.push('text-content-blue-400', 'underline', 'cursor-pointer');
    } else {
      classList.push('cursor-text');
    }

    return classList.join(' ');
  }, [isUrl]);

  if (!cell?.data)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;

  return (
    <div
      style={style}
      onClick={() => {
        if (!isUrl || !cell) return;
        if (readOnly) {
          void openUrl(cell.data, '_blank');
        }
      }}
      className={className}
    >
      {cell?.data}
    </div>
  );
}
