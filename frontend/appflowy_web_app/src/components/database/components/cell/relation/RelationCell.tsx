import { CellProps, RelationCell as RelationCellType } from '@/components/database/components/cell/cell.type';
import RelationItems from '@/components/database/components/cell/relation/RelationItems';

export function RelationCell({ cell, fieldId, style }: CellProps<RelationCellType>) {
  if (!cell?.data) return null;
  return <RelationItems cell={cell} fieldId={fieldId} style={style} />;
}
