import { Node as SlateNode } from 'slate';

export interface BlockJson {
  id: string;
  ty: string;
  data?: string;
  children?: string;
  external_id?: string;
}

export interface Operation {
  type: OperationType;
}

export enum OperationType {
  InsertNode = 'insert_node',
  InsertChildren = 'insert_children',
}

export interface InsertNodeOperation extends Operation {
  type: OperationType.InsertNode;
  node: SlateNode;
}

export interface InsertChildrenOperation extends Operation {
  type: OperationType.InsertChildren;
  blockId: string;
  children: string[];
}
