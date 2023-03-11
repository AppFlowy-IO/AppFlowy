import { RectManager } from "./rect";
import { BlockInterface, BlockData, BlockType, TreeNodeInterface } from '../interfaces/index';

export class TreeManager {

  // RenderTreeManager holds RectManager, which manages the position information of each node in the render tree.
  private rect: RectManager;

  root: TreeNode | null = null;

  map: Map<string, TreeNode> = new Map();

  constructor(private getBlock: (blockId: string) => BlockInterface | null) {
    this.rect = new RectManager(this.getTreeNode);
  }

  /**
   * Get render node data by nodeId
   * @param nodeId string
   * @returns TreeNode
   */
  getTreeNode = (nodeId: string): TreeNodeInterface | null => {
    return this.map.get(nodeId) || null;
  }

  /**
   * build tree node for rendering
   * @param rootId 
   * @returns 
   */
  build(rootId: string): TreeNode | null {
    const head = this.getBlock(rootId);

    if (!head) return null;

    this.root = new TreeNode(head);

    let node = this.root;

    // loop line
    while (node) {
      this.map.set(node.id, node);
      this.rect.orderList.add(node.id);

      const block = this.getBlock(node.id)!;
      const next = block.next ? this.getBlock(block.next) : null;
      const firstChild = block.firstChild ? this.getBlock(block.firstChild) : null;

      // find next line
      if (firstChild) {
        // the next line is node's first child
        const child = new TreeNode(firstChild);
        node.addChild(child);
        node = child;
      } else if (next) {
        // the next line is node's sibling
        const sibling = new TreeNode(next);
        node.parent?.addChild(sibling);
        node = sibling;
      } else {
        // the next line is parent's sibling
        let isFind = false;
        while(node.parent) {
          const parentId = node.parent.id;
          const parent = this.getBlock(parentId)!;
          const parentNext = parent.next ? this.getBlock(parent.next) : null;
          if (parentNext) {
            const parentSibling = new TreeNode(parentNext);
            node.parent?.parent?.addChild(parentSibling);
            node = parentSibling;
            isFind = true;
            break;
          } else {
            node = node.parent;
          }
        }

        if (!isFind) {
          // Exit if next line not found
          break;
        }
        
      }
    }

    return this.root;
  }

  /**
  * update dom rects cache
  */
  updateRects = () => {
    this.rect.build();
  }

  /**
   * get block rect cache
   * @param id string
   * @returns DOMRect
   */
  getNodeRect = (nodeId: string) => {
    return this.rect.getNodeRect(nodeId);
  }

  /**
   * update block rect cache
   * @param id string
   */
  updateNodeRect = (nodeId: string) => {
    this.rect.updateNodeRect(nodeId);
  }
  
  destroy() {
    this.rect?.destroy();
  }
}


class TreeNode implements TreeNodeInterface {
  id: string;
  type: BlockType;
  parent: TreeNode | null = null;
  children: TreeNode[] = [];
  data: BlockData<BlockType>;

  constructor({
    id,
    type,
    data
  }: BlockInterface) {
    this.id = id;
    this.data = data;
    this.type = type;
  }

  addChild(node: TreeNode) {
    node.parent = this;
    this.children.push(node);
  }
}
