// Import dependencies
import { BlockInterface } from '../interfaces';
import { BlockChain, BlockChangeProps } from './core/block_chain';
import { RenderTree } from './view/tree';
import { Operation } from './core/operation';

/**
 * The BlockEditor class manages a block chain and a render tree for a document editor.
 * The block chain stores the content blocks of the document in sequence, while the
 * render tree displays the document as a hierarchical tree structure.
 */
export class BlockEditor {
  // Public properties
  public blockChain: BlockChain; // (local data) the block chain used to store the document
  public renderTree: RenderTree; // the render tree used to display the document
  public operation: Operation;
  /**
   * Constructs a new BlockEditor object.
   * @param id - the ID of the document
   * @param data - the initial data for the document
   */
  constructor(private id: string, data: Record<string, BlockInterface>) {    
    // Create the block chain and render tree
    this.blockChain = new BlockChain(this.blockChange);
    this.operation = new Operation(this.blockChain);
    this.changeDoc(id, data);

    this.renderTree = new RenderTree(this.blockChain);
  }

  /**
   * Updates the document ID and block chain when the document changes.
   * @param id - the new ID of the document
   * @param data - the updated data for the document
   */
  changeDoc = (id: string, data: Record<string, BlockInterface>) => {
    console.log('==== change document ====', id, data);
    
    // Update the document ID and rebuild the block chain
    this.id = id;
    this.blockChain.rebuild(id, data);
  }


  /**
   * Destroys the block chain and render tree.
   */
  destroy = () => {
    // Destroy the block chain and render tree
    this.blockChain.destroy();
    this.renderTree.destroy();
    this.operation.destroy();
  }

  private blockChange = (command: string, data: BlockChangeProps) => {
    this.renderTree.onBlockChange(command, data);
  }

}

