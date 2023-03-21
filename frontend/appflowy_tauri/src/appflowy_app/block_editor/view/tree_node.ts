import { BlockData, BlockType } from '$app/interfaces/index';
import { Block } from '../core/block';

/**
 * Represents a node in a tree structure of blocks.
 */
export class TreeNode {
  id: string;
  type: BlockType;
  parent: TreeNode | null = null;
  children: TreeNode[] = [];
  data: BlockData<BlockType>;

  private forceUpdate?: () => void;

  /**
   * Create a new TreeNode instance.
   * @param block - The block data used to create the node.
   */
  constructor(private _block: Block) {
    this.id = _block.id;
    this.data = _block.data;
    this.type = _block.type;
  }

  registerUpdate(forceUpdate: () => void) {
    this.forceUpdate = forceUpdate;
  }

  unregisterUpdate() {
    this.forceUpdate = undefined;
  }

  reRender() {
    this.forceUpdate?.();
  }

  update(block: Block, children: TreeNode[]) {
    this.data = block.data;
    this.children = [];
    children.forEach(child => {
      this.addChild(child);
    })
  }

  /**
   * Add a child node to the current node.
   * @param node - The child node to add.
   */
  addChild(node: TreeNode) {
    node.parent = this;
    this.children.push(node);
  }

  get block() {
    return this._block;
  }
 
}
