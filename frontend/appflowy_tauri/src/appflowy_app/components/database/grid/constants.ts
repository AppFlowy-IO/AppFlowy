import { Field, RowMeta } from '../application';

export const GridCalculateCountHeight = 40;

export const GRID_ACTIONS_WIDTH = 64;

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

export const fieldsToColumns = (fields: Field[]): GridColumn[] => {
  return [
    {
      type: GridColumnType.Action,
      width: GRID_ACTIONS_WIDTH,
    },
    ...fields.map<GridColumn>((field) => ({
      field,
      width: field.width || DEFAULT_FIELD_WIDTH,
      type: GridColumnType.Field,
    })),
    {
      type: GridColumnType.NewProperty,
      width: DEFAULT_FIELD_WIDTH,
    },
  ];
};

export const rowMetasToRenderRow = (rowMetas: RowMeta[]): RenderRow[] => {
  return [
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

export enum GridColumnType {
  Action,
  Field,
  NewProperty,
}

export interface GridColumn {
  field?: Field;
  width: number;
  type: GridColumnType;
}
