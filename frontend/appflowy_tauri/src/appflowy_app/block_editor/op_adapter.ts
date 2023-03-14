import { BlockType, BlockData } from "../interfaces";

export interface Operation {
  type: string;
  payload: any;
  version?: number;
}

export interface OPAdapterInterface {
  remove(blockId: string): Operation;
  move(blockId: string, newParentId: string, newPrevId: string): Operation
}

export class OPAdapter implements OPAdapterInterface {
  
  newBlock(id: string, data: { type: BlockType, data: BlockData }) {
    const op: Operation = {
      type: 'new',
      payload: { id, data },
    };
    return op;
  }

  remove(blockId: string): Operation {
    const op: Operation = {
      type: 'remove',
      payload: blockId,
    };
    return op;
  }

  move(blockId: string, newParentId: string, newPrevId: string): Operation {
    const op: Operation = {
      type: 'move',
      payload: { blockId, newParentId, newPrevId },
    };
    return op;
  }
}