import { Database } from '$app/interfaces/database';

export enum RenderRowType {
  Fields = 'fields',
  Row = 'row',
  NewRow = 'new-row',
}

export interface FieldRenderRow {
  type: RenderRowType.Fields;
}

export interface CellRenderRow {
  type: RenderRowType.Row;
  data: Database.Row;
}

export interface NewRenderRow {
  type: RenderRowType.NewRow;
}

export type RenderRow = FieldRenderRow | CellRenderRow | NewRenderRow;