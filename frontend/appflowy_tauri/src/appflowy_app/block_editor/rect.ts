import { TreeNodeInterface } from "../interfaces";


export function calculateBlockRect(blockId: string) {
  const el = document.querySelectorAll(`[data-block-id=${blockId}]`)[0];
  return el?.getBoundingClientRect();
}

export class RectManager {
  map: Map<string, DOMRect>;

  orderList: Set<string>;

  private updatedQueue: Set<string>;

  constructor(private getTreeNode: (nodeId: string) => TreeNodeInterface | null) {
    this.map = new Map();
    this.orderList = new Set();
    this.updatedQueue = new Set();
  }

  build() {
    console.log('====update all blocks position====')
    this.orderList.forEach(id => this.updateNodeRect(id));
  }

  getNodeRect = (nodeId: string) => {
    return this.map.get(nodeId) || null;
  }

  update() {
    // In order to avoid excessive calculation frequency
    // calculate and update the block position information in the queue every frame
    requestAnimationFrame(() => {
      // there is nothing to do if the updated queue is empty
      if (this.updatedQueue.size === 0) return;
      console.log(`==== update ${this.updatedQueue.size} blocks rect cache ====`)
      this.updatedQueue.forEach((id: string) => {
        const rect = calculateBlockRect(id);
        this.map.set(id, rect);
        this.updatedQueue.delete(id);
      });
    });
  }

  updateNodeRect = (nodeId: string) => {
    if (this.updatedQueue.has(nodeId)) return;
    let node: TreeNodeInterface | null = this.getTreeNode(nodeId);

    // When one of the blocks is updated
    // the positions of all its parent and child blocks need to be updated
    while(node) {
      node.parent?.children.forEach(child => this.updatedQueue.add(child.id));
      node = node.parent;
    }

    this.update();
  }

  destroy() {
    this.map.clear();
    this.orderList.clear();
    this.updatedQueue.clear();
  }
  
}
