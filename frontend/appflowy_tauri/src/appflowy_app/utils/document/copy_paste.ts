import { BlockData, DocumentBlockJSON, DocumentState, NestedBlock, RangeState } from '$app/interfaces/document';
import { getDeltaByRange } from '$app/utils/document/delta';
import Delta from 'quill-delta';
import { generateId } from '$app/utils/document/block';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { blockConfig } from '$app/constants/document/config';

export function getCopyData(
  node: NestedBlock,
  range: {
    index: number;
    length: number;
  }
): BlockData<any> {
  const nodeDeltaOps = node.data.delta;
  if (!nodeDeltaOps) {
    return {
      ...node.data,
    };
  }
  const delta = getDeltaByRange(new Delta(node.data.delta), range);
  return {
    ...node.data,
    delta: delta.ops,
  };
}

export function getCopyBlock(id: string, document: DocumentState, documentRange: RangeState): DocumentBlockJSON {
  const node = document.nodes[id];
  const range = documentRange.ranges[id] || { index: 0, length: 0 };
  const copyData = getCopyData(node, range);
  return {
    type: node.type,
    data: copyData,
    children: [],
  };
}

export function generateBlocks(data: DocumentBlockJSON[], parentId: string) {
  const blocks: NestedBlock[] = [];
  function dfs(data: DocumentBlockJSON[], parentId: string) {
    data.forEach((item) => {
      const block = {
        id: generateId(),
        type: item.type,
        data: item.data,
        parent: parentId,
        children: generateId(),
      };
      blocks.push(block);
      if (item.children) {
        dfs(item.children, block.id);
      }
    });
  }
  dfs(data, parentId);
  return blocks;
}

export function getInsertBlockActions(blocks: NestedBlock[], prevId: string, controller: DocumentController) {
  return blocks.map((block, index) => {
    const prevBlockId = index === 0 ? prevId : blocks[index - 1].id;
    return controller.getInsertAction(block, prevBlockId);
  });
}

export function getAppendBlockDeltaAction(
  block: NestedBlock,
  appendDelta: Delta,
  isForward: boolean,
  controller: DocumentController
) {
  const nodeDelta = new Delta(block.data.delta);
  const mergeDelta = isForward ? appendDelta.concat(nodeDelta) : nodeDelta.concat(appendDelta);
  return controller.getUpdateAction({
    ...block,
    data: {
      ...block.data,
      delta: mergeDelta.ops,
    },
  });
}
