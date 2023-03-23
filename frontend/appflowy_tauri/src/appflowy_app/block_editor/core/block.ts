import { BlockType, BlockData } from '$app/interfaces/index';
import { generateBlockId } from '$app/utils/block';

/**
 * Represents a single block of content in a document.
 */
export class Block<T extends BlockType = BlockType> {
  id: string;
  type: T;
  data: BlockData<T>;
  parent: Block<BlockType> | null = null; // Pointer to the parent block
  prev: Block<BlockType> | null = null; // Pointer to the previous sibling block
  next: Block<BlockType> | null = null; // Pointer to the next sibling block
  firstChild: Block<BlockType> | null = null; // Pointer to the first child block

  constructor(id: string, type: T, data: BlockData<T>) {
    this.id = id;
    this.type = type;
    this.data = data;
  }

  /**
   * Adds a new child block to the beginning of the current block's children list.
   *
   * @param {Object} content - The content of the new block, including its type and data.
   * @param {string} content.type - The type of the new block.
   * @param {Object} content.data - The data associated with the new block.
   * @returns {Block} The newly created child block.
   */
  prependChild(content: { type: T, data: BlockData<T> }): Block | null {
    const id = generateBlockId();
    const newBlock = new Block(id, content.type, content.data);
    newBlock.reposition(this, null);
    return newBlock;
  }

  /**
   * Add a new sibling block after this block.
   * 
   * @param content The type and data for the new sibling block.
   * @returns The newly created sibling block.
   */
  addSibling(content: { type: T, data: BlockData<T> }): Block | null {
    const id = generateBlockId();
    const newBlock = new Block(id, content.type, content.data);
    newBlock.reposition(this.parent, this);
    return newBlock;
  }

  /**
   * Remove this block and its descendants from the tree.
   * 
   */
  remove() {
    this.detach();
    let child = this.firstChild;
    while (child) {
      const next = child.next;
      child.remove();
      child = next;
    }
  }

  reposition(newParent: Block<BlockType> | null, newPrev: Block<BlockType> | null) {
    // Update the block's parent and siblings
    this.parent = newParent;
    this.prev = newPrev;
    this.next = null;

    if (newParent) {
      const prev = newPrev;
      if (!prev) {
        const next = newParent.firstChild;
        newParent.firstChild = this;
        if (next) {
          this.next = next;
          next.prev = this;
        }
        
      } else {
        // Update the next and prev pointers of the newPrev and next blocks
        if (prev.next !== this) {
          const next = prev.next;
          if (next) {
            next.prev = this
            this.next = next;
          }
          prev.next = this;
        }
      }
      
    }
  }

  // detach the block from its current position in the tree
  detach() {
    if (this.prev) {
      this.prev.next = this.next;
    } else if (this.parent) {
      this.parent.firstChild = this.next;
    }
    if (this.next) {
      this.next.prev = this.prev;
    }
  }

}
