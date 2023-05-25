import { DocumentState, SplitRelationship } from '$app/interfaces/document';
import { DocumentController } from '$app/stores/effects/document/document_controller';
import { createAsyncThunk } from '@reduxjs/toolkit';
import { setCursorBeforeThunk } from '../../cursor';
import { newBlock } from '$app/utils/document/blocks/common';
import { blockConfig } from '$app/constants/document/config';
import { getSplitDelta } from '@/appflowy_app/utils/document/blocks/text/delta';
import { ReactEditor } from 'slate-react';

export const splitNodeThunk = createAsyncThunk(
  'document/splitNode',
  async (payload: { id: string; editor: ReactEditor; controller: DocumentController }, thunkAPI) => {
    const { id, controller, editor } = payload;
    // get the split content
    const { retain, insert } = getSplitDelta(editor);

    const { dispatch, getState } = thunkAPI;
    const state = (getState() as { document: DocumentState }).document;
    const node = state.nodes[id];
    if (!node.parent) return;
    const children = state.children[node.children];
    const parent = state.nodes[node.parent];

    const config = blockConfig[node.type].splitProps;
    // Here we are using the splitProps property of the blockConfig object to determine the type of the new node.
    // if the splitProps property is not defined for the block type, we throw an error.
    if (!config) {
      throw new Error(`Cannot split node of type ${node.type}`);
    }
    const newNodeType = config.nextLineBlockType;
    const relationShip = config.nextLineRelationShip;
    const defaultData = blockConfig[newNodeType].defaultData;
    // if the defaultData property is not defined for the new block type, we throw an error.
    if (!defaultData) {
      throw new Error(`Cannot split node of type ${node.type} to ${newNodeType}`);
    }

    // if the next line is a sibling, parent is the same as the current node, and prev is the current node.
    // otherwise, parent is the current node, and prev is empty.
    const newParentId = relationShip === SplitRelationship.NextSibling ? parent.id : node.id;
    const newPrevId = relationShip === SplitRelationship.NextSibling ? node.id : '';

    const newNode = newBlock<any>(newNodeType, newParentId, {
      ...defaultData,
      delta: insert,
    });
    const retainNode = {
      ...node,
      data: {
        ...node.data,
        delta: retain,
      },
    };
    const insertAction = controller.getInsertAction(newNode, newPrevId);
    const updateAction = controller.getUpdateAction(retainNode);

    // if the next line is a sibling, we need to move the children of the current node to the new node.
    // otherwise, we don't need to do anything.
    const moveChildrenAction =
      relationShip === SplitRelationship.NextSibling
        ? controller.getMoveChildrenAction(
            children.map((id) => state.nodes[id]),
            newNode.id,
            ''
          )
        : [];

    await controller.applyActions([insertAction, ...moveChildrenAction, updateAction]);

    ReactEditor.deselect(editor);
    // set cursor
    await dispatch(setCursorBeforeThunk({ id: newNode.id }));
  }
);
