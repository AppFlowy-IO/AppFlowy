import { RectManager } from "./rect";
import { Block, BlockData, BlockType, TreeNodeImp } from '../interfaces/index';

export class DOMTree {

  rect: RectManager;

  root: TreeNode | null = null;

  map: Map<string, TreeNode> = new Map();

  constructor(private getBlock: (blockId: string) => Block | null) {
    this.rect = new RectManager(this.getTreeNode);
  }

  getTreeNode = (nodeId: string): TreeNodeImp | null => {
    return this.map.get(nodeId) || null;
  }

  blocksToTree(rootId: string) {
    const head = this.getBlock(rootId);

    if (!head) return null;

    this.root = new TreeNode(head);

    let node = this.root;

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

  build(rootId: string): TreeNode | null {
    const root = this.blocksToTree(rootId);
    // update all blocks position
    this.rect.build();
    return root;
  }
  
  destroy() {
    this.rect?.destroy();
  }
}


class TreeNode implements TreeNodeImp {
  id: string;
  type: BlockType;
  parent: TreeNode | null = null;
  children: TreeNode[] = [];
  data: BlockData<BlockType>;

  constructor({
    id,
    type,
    data
  }: Block) {
    this.id = id;
    this.data = data;
    this.type = type;
  }

  addChild(node: TreeNode) {
    node.parent = this;
    this.children.push(node);
  }
}
