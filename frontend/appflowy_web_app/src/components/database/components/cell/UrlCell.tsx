import { FieldId } from '@/application/collab.type';
import { useReadOnly } from '@/application/database-yjs';
import { UrlCell } from '@/components/database/components/cell/cell.type';
import { openUrl, processUrl } from '@/utils/url';
import React, { useMemo } from 'react';

export default function ({ cell }: { cell?: UrlCell; rowId: string; fieldId: FieldId }) {
  const readOnly = useReadOnly();

  const isUrl = useMemo(() => (cell ? processUrl(cell.data) : false), [cell]);

  const className = useMemo(() => {
    const classList = ['select-text'];

    if (isUrl) {
      classList.push('text-content-blue-400', 'underline', 'cursor-pointer');
    } else {
      classList.push('cursor-text');
    }

    return classList.join(' ');
  }, [isUrl]);

  return (
    <div
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
