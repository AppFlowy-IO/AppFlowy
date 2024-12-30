import { TableCellNode } from '@/components/editor/editor.type';
import { isUndefined } from 'lodash-es';

export function sortTableCells (cells: TableCellNode[]): TableCellNode[] {
  return cells.sort((a, b) => {
    if (isUndefined(a.data.colPosition) || isUndefined(a.data.rowPosition) || isUndefined(b.data.colPosition) || isUndefined(b.data.rowPosition)) {
      return 0;
    }

    if (a.data.colPosition === b.data.colPosition) {
      return a.data.rowPosition - b.data.rowPosition;
    }

    return a.data.colPosition - b.data.colPosition;
  });
}
