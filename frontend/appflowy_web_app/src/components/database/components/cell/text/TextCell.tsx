import { useReadOnly } from '@/application/database-yjs';
import { CellProps, TextCell as TextCellType } from '@/components/database/components/cell/cell.type';
import React from 'react';

export function TextCell({ cell, style, placeholder }: CellProps<TextCellType>) {
  const readOnly = useReadOnly();

  if (!cell?.data)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;
  return (
    <div style={style} className={`text-cell w-full cursor-text leading-[1.2] ${readOnly ? 'select-text' : ''}`}>
      {cell?.data}
    </div>
  );
}
