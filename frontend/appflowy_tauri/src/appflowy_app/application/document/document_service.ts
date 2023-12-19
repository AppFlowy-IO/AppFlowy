import {
  ApplyActionPayloadPB,
  BlockActionPB,
  BlockPB,
  OpenDocumentPayloadPB,
  TextDeltaPayloadPB,
} from '@/services/backend';
import {
  DocumentEventApplyAction,
  DocumentEventApplyTextDeltaEvent,
  DocumentEventOpenDocument,
} from '@/services/backend/events/flowy-document2';
import get from 'lodash-es/get';
import { EditorData, EditorNodeType } from '$app/application/document/document.types';
import { Log } from '$app/utils/log';

export function blockPB2Node(block: BlockPB) {
  let data = {};

  try {
    data = JSON.parse(block.data);
  } catch {
    Log.error('[Document Open] json parse error', block.data);
  }

  const node = {
    id: block.id,
    type: block.ty as EditorNodeType,
    parent: block.parent_id,
    children: block.children_id,
    data,
    externalId: block.external_id,
    externalType: block.external_type,
  };

  return node;
}

export const BLOCK_MAP_NAME = 'blocks';
export const META_NAME = 'meta';
export const CHILDREN_MAP_NAME = 'children_map';

export const TEXT_MAP_NAME = 'text_map';
export const EQUATION_PLACEHOLDER = '$';
export async function openDocument(docId: string): Promise<EditorData> {
  const payload = OpenDocumentPayloadPB.fromObject({
    document_id: docId,
  });

  const result = await DocumentEventOpenDocument(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  const documentDataPB = result.val;

  if (!documentDataPB) {
    return Promise.reject('documentDataPB is null');
  }

  const data: EditorData = {
    viewId: docId,
    rootId: documentDataPB.page_id,
    nodeMap: {},
    childrenMap: {},
    relativeMap: {},
    deltaMap: {},
    externalIdMap: {},
  };

  get(documentDataPB, BLOCK_MAP_NAME).forEach((block) => {
    Object.assign(data.nodeMap, {
      [block.id]: blockPB2Node(block),
    });
    data.relativeMap[block.children_id] = block.id;
    if (block.external_id) {
      data.externalIdMap[block.external_id] = block.id;
    }
  });

  get(documentDataPB, [META_NAME, CHILDREN_MAP_NAME]).forEach((child, key) => {
    const blockId = data.relativeMap[key];

    data.childrenMap[blockId] = child.children;
  });

  get(documentDataPB, [META_NAME, TEXT_MAP_NAME]).forEach((delta, key) => {
    const blockId = data.externalIdMap[key];

    data.deltaMap[blockId] = delta ? JSON.parse(delta) : [];
  });

  return data;
}

export async function applyActions(docId: string, actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) {
  if (actions.length === 0) return;
  const payload = ApplyActionPayloadPB.fromObject({
    document_id: docId,
    actions: actions,
  });

  const result = await DocumentEventApplyAction(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  return result.val;
}

export async function applyText(docId: string, textId: string, delta: string) {
  const payload = TextDeltaPayloadPB.fromObject({
    document_id: docId,
    text_id: textId,
    delta: delta,
  });

  const res = await DocumentEventApplyTextDeltaEvent(payload);

  if (!res.ok) {
    return Promise.reject(res.val);
  }

  return res.val;
}
