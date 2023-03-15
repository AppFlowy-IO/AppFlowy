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
  
  newBlock(id: string, data: { type: BlockType, data: BlockData }): Operation {
    const op: Operation = {
      type: 'insert',
      payload: { id, data },
    };
    return op;
  }

  update(blockId: string, data: { paths: string[], data: BlockData }) {
    const op: Operation = {
      type: 'update',
      payload: { id: blockId, data },
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

  moveBulk(startBlockId: string, endBlockId: string, newParentId: string, newPrevId: string): Operation {
    const op: Operation = {
      type: 'move_bulk',
      payload: { startBlockId, endBlockId, newParentId, newPrevId },
    };
    return op;
  }
  
}