import { Database } from '$app/interfaces/database';

export enum RenderRowType {
  Fields = 'fields',
  Row = 'row'
}

export interface FieldRenderRow {
  type: RenderRowType.Fields;
}

export interface CellRenderRow {
  type: RenderRowType.Row;
  data: Database.Row;
}

export type RenderRow = FieldRenderRow | CellRenderRow;