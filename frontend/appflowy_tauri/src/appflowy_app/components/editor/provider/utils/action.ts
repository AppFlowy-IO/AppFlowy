import * as Y from 'yjs';
import { BlockActionPB, BlockActionTypePB } from '@/services/backend';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { YDelta2Delta } from '$app/components/editor/provider/utils/delta';
import { YDelta } from '$app/components/editor/provider/types/y_event';
import { convertToIdList, fillIdRelationMap, findPreviousSibling } from '$app/components/editor/provider/utils/relation';

export function generateUpdateDataActions(yXmlText: Y.XmlText, data: Record<string, string | boolean>) {
  const id = yXmlText.getAttribute('blockId');
  const parentId = yXmlText.getAttribute('parentId');

  return [
    {
      action: BlockActionTypePB.Update,
      payload: {
        block: {
          id,
          data: JSON.stringify(data),
          parent: parentId,
          children: '',
        },
        parent_id: parentId,
      },
    },
  ];
}

export function generateApplyTextActions(yXmlText: Y.XmlText, delta: YDelta) {
  const externalId = yXmlText.getAttribute('textId');

  if (!externalId) return [];

  const deltaString = JSON.stringify(YDelta2Delta(delta));

  return [
    {
      action: BlockActionTypePB.ApplyTextDelta,
      payload: {
        text_id: externalId,
        delta: deltaString,
      },
    },
  ];
}

export function generateDeleteBlockActions({ id, parentId }: { id: string; parentId: string }) {
  return [
    {
      action: BlockActionTypePB.Delete,
      payload: {
        block: {
          id,
        },
        parent_id: parentId,
      },
    },
  ];
}

export function generateInsertBlockActions(
  insertYXmlText: Y.XmlText
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const childrenId = generateId();
  const prev = findPreviousSibling(insertYXmlText);

  const prevId = prev ? prev.getAttribute('blockId') : null;
  const parentId = insertYXmlText.getAttribute('parentId');
  const delta = YDelta2Delta(insertYXmlText.toDelta());
  const data = insertYXmlText.getAttribute('data');
  const type = insertYXmlText.getAttribute('type');
  const id = insertYXmlText.getAttribute('blockId');
  const externalId = insertYXmlText.getAttribute('textId');

  return [
    {
      action: BlockActionTypePB.InsertText,
      payload: {
        text_id: externalId,
        delta: JSON.stringify(delta),
      },
    },
    {
      action: BlockActionTypePB.Insert,
      payload: {
        block: {
          id,
          data: JSON.stringify(data),
          ty: type,
          parent_id: parentId,
          children_id: childrenId,
          external_id: externalId,
          external_type: 'text',
        },
        prev_id: prevId,
        parent_id: parentId,
      },
    },
  ];
}

export function generateMoveBlockActions(yXmlText: Y.XmlText, parentId: string, prevId: string | null) {
  const id = yXmlText.getAttribute('blockId');
  const blockParentId = yXmlText.getAttribute('parentId');

  return [
    {
      action: BlockActionTypePB.Move,
      payload: {
        block: {
          id,
          parent_id: blockParentId,
        },
        parent_id: parentId,
        prev_id: prevId || '',
      },
    },
  ];
}

export function YEvents2BlockActions(
  sharedType: Y.XmlText,
  events: Y.YEvent<Y.XmlText>[]
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const actions: ReturnType<typeof BlockActionPB.prototype.toObject>[] = [];

  events.forEach((event) => {
    const eventActions = YEvent2BlockActions(sharedType, event);

    if (eventActions.length === 0) return;

    actions.push(...eventActions);
  });

  const deleteActions = actions.filter((action) => action.action === BlockActionTypePB.Delete);
  const otherActions = actions.filter((action) => action.action !== BlockActionTypePB.Delete);

  const filteredDeleteActions = filterDeleteActions(deleteActions);

  return [...otherActions, ...filteredDeleteActions];
}

function filterDeleteActions(actions: ReturnType<typeof BlockActionPB.prototype.toObject>[]) {
  return actions.filter((deleteAction) => {
    const { payload } = deleteAction;

    if (payload === undefined) return true;

    const { parent_id } = payload;

    return !actions.some((action) => action.payload?.block?.id === parent_id);
  });
}

export function YEvent2BlockActions(
  sharedType: Y.XmlText,
  event: Y.YEvent<Y.XmlText>
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const { target: yXmlText, keys, delta } = event;
  // when the target is equal to the sharedType, it means that the change type is insert/delete block
  const isBlockEvent = yXmlText === sharedType;

  if (isBlockEvent) {
    return blockOps2BlockActions(sharedType, delta);
  }

  const actions = textOps2BlockActions(yXmlText, delta);

  if (keys.size > 0) {
    actions.push(...parentUpdatedOps2BlockActions(yXmlText, keys));

    actions.push(...dataOps2BlockActions(yXmlText, keys));
  }

  return actions;
}

function textOps2BlockActions(yXmlText: Y.XmlText, ops: YDelta): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  if (ops.length === 0) return [];
  return generateApplyTextActions(yXmlText, ops);
}

function parentUpdatedOps2BlockActions(
  yXmlText: Y.XmlText,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  keys: Map<string, { action: 'update' | 'add' | 'delete'; oldValue: any; newValue: any }>
) {
  const parentUpdated = keys.has('parentId');

  if (!parentUpdated) return [];
  const parentId = yXmlText.getAttribute('parentId');
  const prev = findPreviousSibling(yXmlText) as Y.XmlText;

  const prevId = prev?.getAttribute('blockId');

  fillIdRelationMap(yXmlText, yXmlText.doc?.getMap('idRelationMap') as Y.Map<string>);

  return generateMoveBlockActions(yXmlText, parentId, prevId);
}

function dataOps2BlockActions(
  yXmlText: Y.XmlText,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  keys: Map<string, { action: 'update' | 'add' | 'delete'; oldValue: any; newValue: any }>
) {
  const dataUpdated = keys.has('data');

  if (!dataUpdated) return [];
  const data = yXmlText.getAttribute('data');

  return generateUpdateDataActions(yXmlText, data);
}

function blockOps2BlockActions(
  sharedType: Y.XmlText,
  ops: YDelta
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const actions: ReturnType<typeof BlockActionPB.prototype.toObject>[] = [];

  const idList = sharedType.doc?.get('idList') as Y.XmlText;
  const idRelationMap = sharedType.doc?.getMap('idRelationMap') as Y.Map<string>;
  let index = 0;

  ops.forEach((op) => {
    if (op.insert) {
      if (op.insert instanceof Y.XmlText) {
        const insertYXmlText = op.insert;

        actions.push(...generateInsertBlockActions(insertYXmlText));
      }

      index++;
    } else if (op.retain) {
      index += op.retain;
    } else if (op.delete) {
      const deletedDelta = idList.toDelta().slice(index, index + op.delete) as {
        insert: {
          id: string;
        };
      }[];

      deletedDelta.forEach((delta) => {
        const parentId = idRelationMap.get(delta.insert.id);

        actions.push(
          ...generateDeleteBlockActions({
            id: delta.insert.id,
            parentId: parentId || '',
          })
        );
      });
    }
  });

  idList.applyDelta(convertToIdList(ops));

  return actions;
}
