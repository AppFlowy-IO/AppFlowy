import {
  ApplyActionPayloadPB,
  BlockActionPB,
  BlockPB,
  CloseDocumentPayloadPB,
  ConvertDataToJsonPayloadPB,
  ConvertDocumentPayloadPB,
  InputType,
  OpenDocumentPayloadPB,
  TextDeltaPayloadPB,
} from '@/services/backend';
import {
  DocumentEventApplyAction,
  DocumentEventApplyTextDeltaEvent,
  DocumentEventCloseDocument,
  DocumentEventConvertDataToJSON,
  DocumentEventConvertDocument,
  DocumentEventOpenDocument,
} from '@/services/backend/events/flowy-document';
import get from 'lodash-es/get';
import { EditorData, EditorNodeType } from '$app/application/document/document.types';
import { Log } from '$app/utils/log';
import { Op } from 'quill-delta';
import { Element, Text } from 'slate';
import { generateId, getInlinesWithDelta } from '$app/components/editor/provider/utils/convert';
import { CustomEditor } from '$app/components/editor/command';
import { LIST_TYPES } from '$app/components/editor/command/tab';

export function blockPB2Node(block: BlockPB) {
  let data = {};

  try {
    data = JSON.parse(block.data);
  } catch {
    Log.error('[Document Open] json parse error', block.data);
  }

  return {
    id: block.id,
    type: block.ty as EditorNodeType,
    parent: block.parent_id,
    children: block.children_id,
    data,
    externalId: block.external_id,
    externalType: block.external_type,
  };
}

export const BLOCK_MAP_NAME = 'blocks';
export const META_NAME = 'meta';
export const CHILDREN_MAP_NAME = 'children_map';

export const TEXT_MAP_NAME = 'text_map';
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

export async function closeDocument(docId: string) {
  const payload = CloseDocumentPayloadPB.fromObject({
    document_id: docId,
  });

  const result = await DocumentEventCloseDocument(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  return result.val;
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

export async function getClipboardData(
  docId: string,
  range: {
    start: {
      blockId: string;
      index: number;
      length: number;
    };
    end?: {
      blockId: string;
      index: number;
      length: number;
    };
  }
) {
  const payload = ConvertDocumentPayloadPB.fromObject({
    range: {
      start: {
        block_id: range.start.blockId,
        index: range.start.index,
        length: range.start.length,
      },
      end: range.end
        ? {
            block_id: range.end.blockId,
            index: range.end.index,
            length: range.end.length,
          }
        : undefined,
    },
    document_id: docId,
    parse_types: {
      json: true,
      html: true,
      text: true,
    },
  });

  const result = await DocumentEventConvertDocument(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  return {
    html: result.val.html,
    text: result.val.text,
    json: result.val.json,
  };
}

export async function convertBlockToJson(data: string, type: InputType) {
  const payload = ConvertDataToJsonPayloadPB.fromObject({
    data,
    input_type: type,
  });

  const result = await DocumentEventConvertDataToJSON(payload);

  if (!result.ok) {
    return Promise.reject(result.val);
  }

  try {
    const block = JSON.parse(result.val.json);

    return flattenBlockJson(block);
  } catch (e) {
    return Promise.reject(e);
  }
}

interface BlockJSON {
  type: string;
  children: BlockJSON[];
  data: {
    [key: string]: boolean | string | number | undefined;
  } & {
    delta?: Op[];
  };
}

function flattenBlockJson(block: BlockJSON) {
  const traverse = (block: BlockJSON) => {
    const { delta, ...data } = block.data;

    const slateNode: Element = {
      type: block.type,
      data: data,
      children: [],
      blockId: generateId(),
    };
    const isEmbed = CustomEditor.isEmbedNode(slateNode);

    const textNode: {
      type: EditorNodeType.Text;
      children: (Text | Element)[];
      textId: string;
    } | null = !isEmbed
      ? {
          type: EditorNodeType.Text,
          children: [{ text: '' }],
          textId: generateId(),
        }
      : null;

    if (delta && textNode) {
      textNode.children = getInlinesWithDelta(delta);
    }

    slateNode.children = block.children.map((child) => traverse(child));

    if (textNode) {
      const texts = CustomEditor.getNodeTextContent(textNode);

      if (texts && !LIST_TYPES.includes(block.type as EditorNodeType) && slateNode.type !== EditorNodeType.Page) {
        slateNode.children.unshift(textNode);
      } else if (texts) {
        slateNode.children.unshift({
          type: EditorNodeType.Paragraph,
          children: [textNode],
          blockId: generateId(),
        });
      }
    }

    return slateNode;
  };

  const root = traverse(block);

  return root.children;
}
