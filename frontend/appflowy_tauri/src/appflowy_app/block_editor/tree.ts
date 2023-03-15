import { BlockPositionManager } from "./position";
import { BlockChain } from './block_chain';
import { Block } from './block';
import { TreeNode } from "./tree_node";

export class RenderTree {
  private positionManager: BlockPositionManager;
  private root: TreeNode | null = null;
  private map: Map<string, TreeNode> = new Map();

  constructor(private blockChain: BlockChain) {
    this.positionManager = new BlockPositionManager();
  }

  /**
   * Get the TreeNode data by nodeId
   * @param nodeId string
   * @returns TreeNode|null
   */
  getTreeNode = (nodeId: string): TreeNode | null => {
    // Return the TreeNode instance from the map or null if it does not exist
    return this.map.get(nodeId) || null;
  }

  private createNode(block: Block): TreeNode {
    if (this.map.has(block.id)) {
      return this.map.get(block.id)!;
    }
    return new TreeNode(block, {
      getRect: (id: string) => this.positionManager.getBlockPosition(id),
    });
  }

  /**
   * Build the tree structure from the given rootId
   * @param rootId string
   * @returns TreeNode|null
   */
  build(rootId: string): TreeNode | null {
    // Define a callback function for the blockChain.traverse() method
    const callback = (block: Block) => {
      // Check if the TreeNode instance already exists in the map
      const node = this.createNode(block);

      // Add the TreeNode instance to the map
      this.map.set(block.id, node);

      // Add the first child of the block as a child of the current TreeNode instance
      const firstChild = block.firstChild;
      if (firstChild) {
        const child = this.createNode(firstChild);
        node.addChild(child);
        this.map.set(child.id, child);
      }

      // Add the next block as a sibling of the current TreeNode instance
      const next = block.next;
      if (next) {
        const nextNode = this.createNode(next);
        node.parent?.addChild(nextNode);
        this.map.set(next.id, nextNode);
      }
    }

    // Traverse the blockChain using the callback function
    this.blockChain.traverse(callback);

    // Get the root node from the map and return it
    const root = this.map.get(rootId);
    return root || null;
  }

  observeNode(blockId: string, el: HTMLDivElement) {
    const node = this.getTreeNode(blockId);
    if (!node) return;
    return this.positionManager.observeBlock(node, el);
  }

  updateBlockPosition(blockId: string) {
    const node = this.getTreeNode(blockId);
    if (!node) return;
    this.positionManager.updateBlock(node.id);
  }

  /**
   * Destroy the RenderTreeRectManager instance
   */
  destroy() {
    this.positionManager?.destroy();
  }
}
