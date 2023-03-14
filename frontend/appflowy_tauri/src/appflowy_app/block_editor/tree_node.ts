import { BlockData, BlockType } from '../interfaces/index';
import { Block } from './block';
import { BlockPosition } from './position';

/**
 * Represents a node in a tree structure of blocks.
 */
export class TreeNode {
  id: string;
  type: BlockType;
  parent: TreeNode | null = null;
  children: TreeNode[] = [];
  data: BlockData<BlockType>;
  
  private _rect: {
    getRect: () => BlockPosition | null;
  }
  /**
   * Create a new TreeNode instance.
   * @param block - The block data used to create the node.
   */
  constructor(private _block: Block, opts: {
    getRect: (nodeId: string) => BlockPosition | null;
  }) {
    this.id = _block.id;
    this.data = _block.data;
    this.type = _block.type;
    this._rect = {
      getRect: () => opts.getRect(this.id)
    }
  }

  /**
   * Add a child node to the current node.
   * @param node - The child node to add.
   */
  addChild(node: TreeNode) {
    node.parent = this;
    this.children.push(node);
  }

  get rect() {
    return this._rect;
  }

  get block() {
    return this._block;
  }
 
}
