import { BlockChain, BlockChangeProps } from '../core/block_chain';
import { Block } from '../core/block';
import { TreeNode } from "./tree_node";
import { BlockPositionManager } from './block_position';
import { filterSelections } from '@/appflowy_app/utils/block_selection';

export class RenderTree {
  public blockPositionManager?: BlockPositionManager;

  private map: Map<string, TreeNode> = new Map();
  private root: TreeNode | null = null;
  private selections: Set<string> = new Set();
  constructor(private blockChain: BlockChain) {
  }


  createPositionManager(container: HTMLDivElement) {
    this.blockPositionManager = new BlockPositionManager(container);
  }

  observeBlock(node: HTMLDivElement) {
    return this.blockPositionManager?.observeBlock(node);
  }

  getBlockPosition(nodeId: string) {
    return this.blockPositionManager?.getBlockPosition(nodeId) || null;
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
    const node = new TreeNode(block);
    this.map.set(block.id, node);
    return node;
  }


  buildDeep(rootId: string): TreeNode | null {
    this.map.clear();
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
    const root = this.map.get(rootId)!;
    this.root = root;
    return root || null;
  }


  forceUpdate(nodeId: string, shouldUpdateChildren = false) {
    const block = this.blockChain.getBlock(nodeId);
    if (!block) return null;
    const node = this.createNode(block);
    if (!node) return null;

    if (shouldUpdateChildren) {
      const children: TreeNode[] = [];
      let childBlock = block.firstChild;

      while(childBlock) {
        const child = this.createNode(childBlock);
        child.update(childBlock, child.children);
        children.push(child);
        childBlock = childBlock.next;
      }

      node.update(block, children);
      node?.reRender();
      node?.children.forEach(child => {
        child.reRender();
      })
    } else {
      node.update(block, node.children);
      node?.reRender();
    }
  }

  onBlockChange(command: string, data: BlockChangeProps) {
    const { block, startBlock, endBlock, oldParentId = '', oldPrevId = '' } = data;
    switch (command) {
      case 'insert':
        if (block?.parent) this.forceUpdate(block.parent.id, true);
        break;
      case 'update':
        this.forceUpdate(block!.id);
        break;
      case 'move':
        if (oldParentId) this.forceUpdate(oldParentId, true);
        if (block?.parent) this.forceUpdate(block.parent.id, true);
        if (startBlock?.parent) this.forceUpdate(startBlock.parent.id, true);
        break;
      default:
        break;
    }
    
  }

  updateSelections(selections: string[]) {
    const newSelections = filterSelections<TreeNode>(selections, this.map);

    let isDiff = false;
    if (newSelections.length !== this.selections.size) {
      isDiff = true;
    }

    const selectedBlocksSet = new Set(newSelections);
    if (Array.from(this.selections).some((id) => !selectedBlocksSet.has(id))) {
      isDiff = true;
    }

    if (isDiff) {
      const shouldUpdateIds = new Set([...this.selections, ...newSelections]);
      this.selections = selectedBlocksSet;
      shouldUpdateIds.forEach((id) => this.forceUpdate(id));
    }
  }

  isSelected(nodeId: string) {
    return this.selections.has(nodeId);
  }

  /**
   * Destroy the RenderTreeRectManager instance
   */
  destroy() {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.blockChain = null;
  }
}
