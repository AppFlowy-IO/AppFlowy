import { BlockChain } from './block_chain';
import { BlockInterface, BlockType, InsertOpData, LocalOp, UpdateOpData, moveOpData, moveRangeOpData, removeOpData, BlockData } from '$app/interfaces';
import { BlockEditorSync } from './sync';
import { Block } from './block';

export class Operation {
  private sync: BlockEditorSync;
  constructor(private blockChain: BlockChain) {
    this.sync = new BlockEditorSync();
  }


  splitNode(
    retainId: string,
    retainData: { path: string[], value: any },
    newBlockData: {
      type: BlockType;
      data: BlockData
    }) {
    const ops: {
      type: LocalOp['type'];
      data: LocalOp['data'];
    }[] = [];
    const newBlock = this.blockChain.addSibling(retainId, newBlockData);
    const parentId = newBlock?.parent?.id;
    const retainBlock = this.blockChain.getBlock(retainId);
    if (!newBlock || !parentId || !retainBlock) return null;

    const insertOp = this.getInsertNodeOp({
      id: newBlock.id,
      next: newBlock.next?.id || null,
      firstChild: newBlock.firstChild?.id || null,
      data: newBlock.data,
      type: newBlock.type,
    }, parentId, retainId);

    const updateOp = this.getUpdateNodeOp(retainId, retainData.path, retainData.value);
    this.blockChain.updateBlock(retainId, retainData);

    ops.push(insertOp, updateOp);
    const startBlock = retainBlock.firstChild;
    if (startBlock) {
      const startBlockId = startBlock.id;
      let next: Block | null = startBlock.next;
      let endBlockId = startBlockId;
      while (next) {
        endBlockId = next.id;
        next = next.next;
      }
      
      const moveOp = this.getMoveRangeOp([startBlockId, endBlockId], newBlock.id);
      this.blockChain.moveBulk(startBlockId, endBlockId, newBlock.id, '');
      ops.push(moveOp);
    }

    this.sync.sendOps(ops);

    return newBlock;
  }

  updateNode<T>(blockId: string, path: string[], value: T) {
    const op = this.getUpdateNodeOp(blockId, path, value);
    this.blockChain.updateBlock(blockId, {
      path,
      value
    });
    this.sync.sendOps([op]);
  }
  private getUpdateNodeOp<T>(blockId: string, path: string[], value: T): {
    type: 'update',
    data: UpdateOpData
  } {
    return {
      type: 'update',
      data: {
        blockId,
        path: path,
        value
      }
    };
  }

  private getInsertNodeOp<T extends BlockInterface>(block: T, parentId: string, prevId?: string): {
    type: 'insert';
    data: InsertOpData
  } {
    return {
      type: 'insert',
      data: {
        block,
        parentId,
        prevId
      }
    }
  }

  private getMoveRangeOp(range: [string, string], newParentId: string, newPrevId?: string): {
    type: 'move_range',
    data: moveRangeOpData
  } {
    return {
      type: 'move_range',
      data: {
        range,
        newParentId,
        newPrevId,
      }
    }
  }

  private getMoveOp(blockId: string, newParentId: string, newPrevId?: string): {
    type: 'move',
    data: moveOpData
  } {
    return {
      type: 'move',
      data: {
        blockId,
        newParentId,
        newPrevId
      }
    }
  }

  private getRemoveOp(blockId: string): {
    type: 'remove'
    data: removeOpData
  } {
    return {
      type: 'remove',
      data: {
        blockId
      }
    }
  }

  applyOperation(op: LocalOp) {
    switch (op.type) {
      case 'insert':

        break;

      default:
        break;
    }
  }

  destroy() {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.blockChain = null;
  }
}