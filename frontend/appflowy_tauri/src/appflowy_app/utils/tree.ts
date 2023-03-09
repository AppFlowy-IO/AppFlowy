import { Block } from "../interfaces";
import { getDocumentBlocksMap } from './block_context';

const blockPositionsMap = new Map<string, Map<string, DOMRect>>();
const updateBlocks = new Map<string, Set<string>>();
export const nodeList = new Map<string, Set<string>>();

export function clearTreeCache(id: string) {
  blockPositionsMap.get(id)?.clear();
  updateBlocks.get(id)?.clear();
  nodeList.get(id)?.clear();
}

function initializeCache(id: string) {
  if (!nodeList.has(id)) {
    nodeList.set(id, new Set());
  }

  if (!blockPositionsMap.has(id)) {
    blockPositionsMap.set(id, new Map());
  }

  if (!updateBlocks.has(id)) {
    updateBlocks.set(id, new Set());
  }
}


export function buildTree(id: string, blocksMap: Record<string, Block>) {
  const head = blocksMap[id];
  let node: Block | null = head;
  
  initializeCache(id);

  const list = nodeList.get(id);
  while(node) {
    list?.add(node.id);
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


export function calculateBlockRect(blockId: string) {
  const el = document.querySelectorAll(`[data-block-id=${blockId}]`)[0];
  return el?.getBoundingClientRect();
}

export function updateDocumentRectCache(documentId: string) {
  nodeList.get(documentId)?.forEach(id => updateBlockPositionCache(documentId, id))
}

export function updateBlockPositionCache(documentId: string, blockId: string) {
  const blocksMap = getDocumentBlocksMap(documentId);
  if (!blocksMap) return;

  let block = blocksMap[blockId];
  const waitUpdate = updateBlocks.get(documentId);
  while(block.parent) {
    const parent = blocksMap[block.parent];
    parent.children?.forEach(item => waitUpdate?.add(item.id)) || [];
    block = parent;
  }

  requestAnimationFrame(() => {
    waitUpdate?.size && console.log(`==== update ${waitUpdate.size} blocks rect cache ====`)
    waitUpdate?.forEach((id: string) => {
      const rect = calculateBlockRect(id);
      blockPositionsMap.get(documentId)?.set(id, rect);
      waitUpdate?.delete(id);
    });
  });
}

export function getBlockRect(documentId: string, blockId: string) {
  return blockPositionsMap.get(documentId)?.get(blockId);
}
