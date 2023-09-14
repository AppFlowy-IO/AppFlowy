import { BlockData, BlockType, DocumentState, NestedBlock, SplitRelationship } from '$app/interfaces/document';
import { generateId, getNextLineId, getPrevLineId } from '$app/utils/document/block';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import Delta, { Op } from 'quill-delta';
import { blockConfig } from '$app/constants/document/config';

export class BlockDeltaOperator {
  constructor(
    private state: DocumentState,
    private controller?: DocumentController,
    private updatePageName?: (name: string) => Promise<void>
  ) {}

  getBlock = (blockId: string) => {
    return this.state.nodes[blockId];
  };

  getExternalId = (blockId: string) => {
    return this.getBlock(blockId)?.externalId;
  };

  getDeltaStrWithExternalId = (externalId: string) => {
    return this.state.deltaMap[externalId];
  };

  getDeltaWithExternalId = (externalId: string) => {
    const deltaStr = this.getDeltaStrWithExternalId(externalId);

    if (!deltaStr) return;
    return new Delta(JSON.parse(deltaStr));
  };

  getDeltaWithBlockId = (blockId: string) => {
    const externalId = this.getExternalId(blockId);

    if (!externalId) return;
    return this.getDeltaWithExternalId(externalId);
  };

  hasDelta = (blockId: string) => {
    const externalId = this.getExternalId(blockId);

    if (!externalId) return false;
    return !!this.getDeltaStrWithExternalId(externalId);
  };

  getDeltaText = (delta: Delta) => {
    return delta.ops.map((op) => op.insert).join('');
  };

  sliceDeltaWithBlockId = (blockId: string, startIndex: number, endIndex?: number) => {
    const delta = this.getDeltaWithBlockId(blockId);

    return delta?.slice(startIndex, endIndex);
  };

  getSplitDelta = (blockId: string, index: number, length: number) => {
    const externalId = this.getExternalId(blockId);

    if (!externalId) return;
    const delta = this.getDeltaWithExternalId(externalId);

    if (!delta) return;
    const diff = new Delta().retain(index).delete(delta.length() - index);
    const updateDelta = delta.slice(0, index);
    const insertDelta = delta.slice(index + length);

    return {
      diff,
      updateDelta,
      insertDelta,
    };
  };

  getApplyDeltaAction = (blockId: string, delta: Delta) => {
    const block = this.getBlock(blockId);
    const deltaStr = JSON.stringify(delta.ops);

    return this.controller?.getApplyTextDeltaAction(block, deltaStr);
  };

  getNewTextLineActions = ({
    blockId,
    delta,
    parentId,
    type = BlockType.TextBlock,
    prevId,
    data = {},
  }: {
    blockId: string;
    delta: Delta;
    parentId: string;
    type: BlockType;
    prevId: string | null;
    data?: BlockData<any>;
  }) => {
    const externalId = generateId();
    const block = {
      id: blockId,
      type,
      externalId,
      externalType: 'text',
      parent: parentId,
      children: generateId(),
      data,
    };
    const deltaStr = JSON.stringify(delta.ops);

    if (!this.controller) return [];
    return this.controller?.getInsertTextActions(block, deltaStr, prevId);
  };

  splitText = async (
    startBlock: {
      id: string;
      index: number;
    },
    endBlock: {
      id: string;
      index: number;
    },
    shiftKey?: boolean
  ) => {
    if (!this.controller) return;

    const startNode = this.getBlock(startBlock.id);
    const endNode = this.getBlock(endBlock.id);
    const startNodeIsRoot = !startNode.parent;

    if (!startNode || !endNode) return;
    const startNodeDelta = this.getDeltaWithBlockId(startNode.id);
    const endNodeDelta = this.getDeltaWithBlockId(endNode.id);

    if (!startNodeDelta || !endNodeDelta) return;
    let diff: Delta, insertDelta;

    if (startNode.id === endNode.id) {
      const splitResult = this.getSplitDelta(startNode.id, startBlock.index, endBlock.index - startBlock.index);

      if (!splitResult) return;
      diff = splitResult.diff;
      insertDelta = splitResult.insertDelta;
    } else {
      const startSplitResult = this.getSplitDelta(
        startNode.id,
        startBlock.index,
        startNodeDelta.length() - startBlock.index
      );

      const endSplitResult = this.getSplitDelta(endNode.id, 0, endBlock.index);

      if (!startSplitResult || !endSplitResult) return;
      diff = startSplitResult.diff;
      insertDelta = endSplitResult.insertDelta;
    }

    if (!diff || !insertDelta) return;

    const actions = [];

    const { nextLineBlockType, nextLineRelationShip } = blockConfig[startNode.type]?.splitProps || {
      nextLineBlockType: BlockType.TextBlock,
      nextLineRelationShip: SplitRelationship.NextSibling,
    };
    const parentId =
      nextLineRelationShip === SplitRelationship.NextSibling && startNode.parent ? startNode.parent : startNode.id;
    const prevId = nextLineRelationShip === SplitRelationship.NextSibling && startNode.parent ? startNode.id : null;

    let newLineId = startNode.id;

    // delete middle nodes
    if (startNode.id !== endNode.id) {
      actions.push(...this.getDeleteMiddleNodesActions(startNode.id, endNode.id));
    }

    if (shiftKey) {
      const enter = new Delta().insert('\n');
      const newOps = diff.ops.concat(enter.ops.concat(insertDelta.ops));

      diff = new Delta(newOps);
      if (startNode.id !== endNode.id) {
        // move the children of endNode to startNode
        actions.push(...this.getMoveChildrenActions(endNode.id, startNode));
      }
    } else {
      newLineId = generateId();
      actions.push(
        ...this.getNewTextLineActions({
          blockId: newLineId,
          delta: insertDelta,
          parentId,
          type: nextLineBlockType,
          prevId,
        })
      );
      if (!startNodeIsRoot) {
        // move the children of startNode to newLine
        actions.push(
          ...this.getMoveChildrenActions(
            startNode.id,
            {
              id: newLineId,
              type: nextLineBlockType,
            },
            [endNode.id]
          )
        );
      }

      if (startNode.id !== endNode.id) {
        // move the children of endNode to newLine
        actions.push(
          ...this.getMoveChildrenActions(endNode.id, {
            id: newLineId,
            type: nextLineBlockType,
          })
        );
      }
    }

    if (startNode.id !== endNode.id) {
      // delete end node
      const deleteEndNodeAction = this.controller.getDeleteAction(endNode);

      actions.push(deleteEndNodeAction);
    }

    if (startNode.parent) {
      // apply delta
      const applyDeltaAction = this.getApplyDeltaAction(startNode.id, diff);

      if (applyDeltaAction) actions.unshift(applyDeltaAction);
    } else {
      await this.updateRootNodeDelta(startNode.id, diff);
    }

    await this.controller.applyActions(actions);

    return newLineId;
  };

  deleteText = async (
    startBlock: {
      id: string;
      index: number;
    },
    endBlock: {
      id: string;
      index: number;
    },
    insertChar?: string
  ) => {
    if (!this.controller) return;
    const startNode = this.getBlock(startBlock.id);
    const endNode = this.getBlock(endBlock.id);

    if (!startNode || !endNode) return;
    const startNodeDelta = this.getDeltaWithBlockId(startNode.id);
    const endNodeDelta = this.getDeltaWithBlockId(endNode.id);

    if (!startNodeDelta || !endNodeDelta) return;

    let startDiff: Delta | undefined;
    const actions = [];

    if (startNode.id === endNode.id) {
      const length = endBlock.index - startBlock.index;

      const newOps: Op[] = [
        {
          retain: startBlock.index,
        },
        {
          delete: length,
        },
      ];

      if (insertChar) {
        newOps.push({
          insert: insertChar,
        });
      }

      startDiff = new Delta(newOps);
    } else {
      const startSplitResult = this.getSplitDelta(
        startNode.id,
        startBlock.index,
        startNodeDelta.length() - startBlock.index
      );
      const endSplitResult = this.getSplitDelta(endNode.id, 0, endBlock.index);

      if (!startSplitResult || !endSplitResult) return;
      const insertDelta = endSplitResult.insertDelta;
      const newOps = [...startSplitResult.diff.ops];

      if (insertChar) {
        newOps.push({
          insert: insertChar,
        });
      }

      newOps.push(...insertDelta.ops);
      startDiff = new Delta(newOps);
      // delete middle nodes
      actions.push(...this.getDeleteMiddleNodesActions(startNode.id, endNode.id));
      // move the children of endNode to startNode
      actions.push(...this.getMoveChildrenActions(endNode.id, startNode));
      // delete end node
      const deleteEndNodeAction = this.controller.getDeleteAction(endNode);

      actions.push(deleteEndNodeAction);
    }

    if (!startDiff) return;
    if (startNode.parent) {
      const applyDeltaAction = this.getApplyDeltaAction(startNode.id, startDiff);

      if (applyDeltaAction) actions.unshift(applyDeltaAction);
    } else {
      await this.updateRootNodeDelta(startNode.id, startDiff);
    }

    await this.controller.applyActions(actions);

    return startNode.id;
  };

  mergeText = async (targetId: string, sourceId: string) => {
    if (!this.controller || targetId === sourceId) return;
    const startNode = this.getBlock(targetId);
    const endNode = this.getBlock(sourceId);

    if (!startNode || !endNode) return;
    const startNodeDelta = this.getDeltaWithBlockId(startNode.id);
    const endNodeDelta = this.getDeltaWithBlockId(endNode.id);

    if (!startNodeDelta || !endNodeDelta) return;

    const startNodeIsRoot = !startNode.parent;
    const actions = [];
    const index = startNodeDelta.length();
    const retain = new Delta().retain(startNodeDelta.length());
    const newOps = [...retain.ops, ...endNodeDelta.ops];
    const diff = new Delta(newOps);

    if (!startNodeIsRoot) {
      const applyDeltaAction = this.getApplyDeltaAction(startNode.id, diff);

      if (applyDeltaAction) actions.push(applyDeltaAction);
    } else {
      await this.updateRootNodeDelta(startNode.id, diff);
    }

    const moveChildrenActions = this.getMoveChildrenActions(endNode.id, startNode);

    // move the children of endNode to startNode
    actions.push(...moveChildrenActions);
    // delete end node
    const deleteEndNodeAction = this.controller.getDeleteAction(endNode);

    actions.push(deleteEndNodeAction);

    await this.controller.applyActions(actions);
    return {
      id: targetId,
      index,
    };
  };
  updateRootNodeDelta = async (id: string, diff: Delta) => {
    const nodeDelta = this.getDeltaWithBlockId(id);
    const delta = nodeDelta?.compose(diff);

    const name = delta ? this.getDeltaText(delta) : '';

    await this.updatePageName?.(name);
  };

  getMoveChildrenActions = (
    blockId: string,
    newParent: {
      id: string;
      type: BlockType;
    },
    excludeIds?: string[]
  ) => {
    if (!this.controller) return [];
    const block = this.getBlock(blockId);
    const config = blockConfig[newParent.type];

    if (!config.canAddChild) return [];
    const childrenId = block.children;
    const children = this.state.children[childrenId]
      .filter((id) => !excludeIds || (excludeIds && !excludeIds.includes(id)))
      .map((id) => this.getBlock(id));

    return this.controller.getMoveChildrenAction(children, newParent.id, null);
  };

  getDeleteMiddleNodesActions = (startId: string, endId: string) => {
    const controller = this.controller;

    if (!controller) return [];
    const middleIds = this.getMiddleIds(startId, endId);

    return middleIds.map((id) => controller.getDeleteAction(this.getBlock(id)));
  };

  getMiddleIds = (startId: string, endId: string) => {
    const middleIds = [];
    let currentId: string | undefined = startId;

    while (currentId && currentId !== endId) {
      const nextId = getNextLineId(this.state, currentId);

      if (nextId && nextId !== endId) {
        middleIds.push(nextId);
      }

      currentId = nextId;
    }

    return middleIds;
  };

  findPrevTextLine = (blockId: string) => {
    let currentId: string | undefined = blockId;

    while (currentId) {
      const prevId = getPrevLineId(this.state, currentId);

      if (prevId && this.hasDelta(prevId)) {
        return prevId;
      }

      currentId = prevId;
    }
  };

  findNextTextLine = (blockId: string) => {
    let currentId: string | undefined = blockId;

    while (currentId) {
      const nextId = getNextLineId(this.state, currentId);

      if (nextId && this.hasDelta(nextId)) {
        return nextId;
      }

      currentId = nextId;
    }
  };
}
