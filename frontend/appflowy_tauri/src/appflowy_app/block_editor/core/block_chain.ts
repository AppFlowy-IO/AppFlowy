import { BlockData, BlockInterface, BlockType } from '$app/interfaces/index';
import { set } from '../../utils/tool';
import { Block } from './block';
export interface BlockChangeProps {
  block?: Block,
  startBlock?: Block,
  endBlock?: Block,
  oldParentId?: string,
  oldPrevId?: string
}
export class BlockChain {
  private map: Map<string, Block<BlockType>> = new Map();
  public head: Block<BlockType> | null = null;

  constructor(private onBlockChange: (command: string, data: BlockChangeProps) => void) {

  }
  /**
   * generate blocks from doc data
   * @param id doc id
   * @param map doc data
   */
  rebuild = (id: string, map: Record<string, BlockInterface<BlockType>>) => {
    this.map.clear();
    this.head = this.createBlock(id, map[id].type, map[id].data);

    const callback = (block: Block) => {
      const firstChildId = map[block.id].firstChild;
      const nextId = map[block.id].next;
      if (!block.firstChild && firstChildId) {
        block.firstChild = this.createBlock(firstChildId, map[firstChildId].type, map[firstChildId].data);
        block.firstChild.parent = block;
        block.firstChild.prev = null;
      }
      if (!block.next && nextId) {
        block.next = this.createBlock(nextId, map[nextId].type, map[nextId].data);
        block.next.parent = block.parent;
        block.next.prev = block;
      }
    }
    this.traverse(callback);
  }

  /**
   * Traversing the block list from front to back
   * @param callback It will be call when the block visited
   * @param block block item, it will be equal head node when the block item is undefined
   */
  traverse(callback: (_block: Block<BlockType>) => void, block?: Block<BlockType>) {
    let currentBlock: Block | null = block || this.head;
    while (currentBlock) {
      callback(currentBlock);
      if (currentBlock.firstChild) {
        this.traverse(callback, currentBlock.firstChild);
      }
      currentBlock = currentBlock.next;
    }
  }

  /**
   * get block data
   * @param blockId string
   * @returns Block
   */
  getBlock = (blockId: string) => {
    return this.map.get(blockId) || null;
  }

  destroy() {
    this.map.clear();
    this.head = null;
    this.onBlockChange = () => null;
  }

  /**
   * Adds a new child block to the beginning of the current block's children list.
   *
   * @param {string} parentId
   * @param {Object} content - The content of the new block, including its type and data.
   * @param {string} content.type - The type of the new block.
   * @param {Object} content.data - The data associated with the new block.
   * @returns {Block} The newly created child block.
   */
  prependChild(blockId: string, content: { type: BlockType, data: BlockData<BlockType> }): Block | null {
    const parent = this.getBlock(blockId);
    if (!parent) return null;
    const newBlock = parent.prependChild(content);

    if (newBlock) {
      this.map.set(newBlock?.id, newBlock);
      this.onBlockChange('insert', { block: newBlock });
    }

    return newBlock;
  }

  /**
   * Add a new sibling block after this block.
   * @param {string} blockId
   * @param content The type and data for the new sibling block.
   * @returns The newly created sibling block.
   */
  addSibling(blockId: string, content: { type: BlockType, data: BlockData<BlockType> }): Block | null {
    const block = this.getBlock(blockId);
    if (!block) return null;
    const newBlock = block.addSibling(content);
    if (newBlock) {
      this.map.set(newBlock?.id, newBlock);
      this.onBlockChange('insert', { block: newBlock });
    }
    return newBlock;
  }

  /**
   * Remove this block and its descendants from the tree.
   * @param {string} blockId
   */
  remove(blockId: string) {
    const block = this.getBlock(blockId);
    if (!block) return;
    block.remove();
    this.map.delete(block.id);
    this.onBlockChange('delete', { block });
    return block;
  }

  /**
   * Move this block to a new position in the tree.
   * @param {string} blockId
   * @param newParentId The new parent block of this block. If null, the block becomes a top-level block.
   * @param newPrevId The new previous sibling block of this block. If null, the block becomes the first child of the new parent.
   * @returns This block after it has been moved.
   */
  move(blockId: string, newParentId: string, newPrevId: string): Block | null {
    const block = this.getBlock(blockId);
    if (!block) return null;
    const oldParentId = block.parent?.id;
    const oldPrevId = block.prev?.id;
    block.detach();
    const newParent = this.getBlock(newParentId);
    const newPrev = this.getBlock(newPrevId);
    block.reposition(newParent, newPrev);
    this.onBlockChange('move', {
      block,
      oldParentId,
      oldPrevId
    });
    return block;
  }

  updateBlock(id: string, data: { path: string[], value: any }) {
    const block = this.getBlock(id);
    if (!block) return null;
    
    set(block, data.path, data.value);
    this.onBlockChange('update', {
      block
    });
    return block;
  }


  moveBulk(startBlockId: string, endBlockId: string, newParentId: string, newPrevId: string): [Block, Block] | null {
    const startBlock = this.getBlock(startBlockId);
    const endBlock = this.getBlock(endBlockId);
    if (!startBlock || !endBlock) return null;

    if (startBlockId === endBlockId) {
      const block = this.move(startBlockId, newParentId, '');
      if (!block) return null;
      return [block, block];
    }

    const oldParent = startBlock.parent;
    const prev = startBlock.prev;
    const newParent = this.getBlock(newParentId);
    if (!oldParent || !newParent) return null;

    if (oldParent.firstChild === startBlock) {
      oldParent.firstChild = endBlock.next;
    } else if (prev) {
      prev.next = endBlock.next;
    }
    startBlock.prev = null;
    endBlock.next = null;

    startBlock.parent = newParent;
    endBlock.parent = newParent;
    const newPrev = this.getBlock(newPrevId);
    if (!newPrev) {
      const firstChild = newParent.firstChild;
      newParent.firstChild = startBlock;
      if (firstChild) {
        endBlock.next = firstChild;
        firstChild.prev = endBlock;
      }
    } else {
      const next = newPrev.next;
      newPrev.next = startBlock;
      endBlock.next = next;
      if (next) {
        next.prev = endBlock;
      }
    }

    this.onBlockChange('move', {
      startBlock,
      endBlock,
      oldParentId: oldParent.id,
      oldPrevId: prev?.id
    });
    
    return [
      startBlock,
      endBlock
    ];
  }


  private createBlock(id: string, type: BlockType, data: BlockData<BlockType>) {
    const block = new Block(id, type, data);
    this.map.set(id, block);
    return block;
  }
}