import { RowMeta } from '../../application';

export const GridCalculateCountHeight = 40;

export const DEFAULT_FIELD_WIDTH = 150;

export enum RenderRowType {
  Fields = 'fields',
  Row = 'row',
  NewRow = 'new-row',
  CalculateRow = 'calculate-row',
}

export interface CalculateRenderRow {
  type: RenderRowType.CalculateRow;
}

export interface FieldRenderRow {
  type: RenderRowType.Fields;
}

export interface CellRenderRow {
  type: RenderRowType.Row;
  data: {
    meta: RowMeta;
  };
}

export interface NewRenderRow {
  type: RenderRowType.NewRow;
  data: {
    startRowId?: string;
    groupId?: string;
  };
}

export type RenderRow = FieldRenderRow | CellRenderRow | NewRenderRow | CalculateRenderRow;

export const rowMetasToRenderRow = (rowMetas: RowMeta[]): RenderRow[] => {
  return [
    {
      type: RenderRowType.Fields,
    },
    ...rowMetas.map<RenderRow>((rowMeta) => ({
      type: RenderRowType.Row,
      data: {
        meta: rowMeta,
      },
    })),
    {
      type: RenderRowType.NewRow,
      data: {
        startRowId: rowMetas.at(-1)?.id,
      },
    },
    {
      type: RenderRowType.CalculateRow,
    },
  ];
};
