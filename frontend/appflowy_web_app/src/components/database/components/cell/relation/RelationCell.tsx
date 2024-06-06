import { FieldType } from '@/application/database-yjs';
import { CellProps, RelationCell as RelationCellType } from '@/application/database-yjs/cell.type';
import RelationItems from '@/components/database/components/cell/relation/RelationItems';
import React from 'react';

export function RelationCell({ cell, fieldId, style, placeholder }: CellProps<RelationCellType>) {
  if (cell?.fieldType !== FieldType.Relation) return null;

  if (!cell?.data)
    return placeholder ? (
      <div style={style} className={'text-text-placeholder'}>
        {placeholder}
      </div>
    ) : null;

  return <RelationItems cell={cell} fieldId={fieldId} style={style} />;
}
