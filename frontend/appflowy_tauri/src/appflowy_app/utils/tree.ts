import { Block } from "../interfaces";

export function buildTree(id: string, blocksMap: Record<string, Block>) {
  const head = blocksMap[id];
  let node: Block | null = head;
  while(node) {

    if (node.parent) {
      const parent = blocksMap[node.parent];
      !parent.children && (parent.children = []);
      parent.children.push(node);
    }
    
    if (node.firstChild) {
      node = blocksMap[node.firstChild];
    } else  if (node.next) {
      node = blocksMap[node.next];
    } else {
      while(node && node?.parent) {
        const parent: Block | null = blocksMap[node.parent];
        if (parent?.next) {
          node = blocksMap[parent.next];
          break;
        } else {
          node = parent;
        }
      }
      if (node.id === head.id) {
        node = null;
        break;
      }
    } 

  }
  return head;
}
