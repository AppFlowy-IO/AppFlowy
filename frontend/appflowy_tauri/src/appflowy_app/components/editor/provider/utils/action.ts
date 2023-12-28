import * as Y from 'yjs';
import { BlockActionPB, BlockActionTypePB } from '@/services/backend';
import { generateId } from '$app/components/editor/provider/utils/convert';
import { YDelta2Delta } from '$app/components/editor/provider/utils/delta';
import { YDelta } from '$app/components/editor/provider/types/y_event';
import { getInsertTarget, getYTarget } from '$app/components/editor/provider/utils/relation';
import { EditorNodeType } from '$app/application/document/document.types';
import { Log } from '$app/utils/log';

export function YEvents2BlockActions(
  backupDoc: Readonly<Y.Doc>,
  events: Y.YEvent<Y.XmlText>[]
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const actions: ReturnType<typeof BlockActionPB.prototype.toObject>[] = [];

  events.forEach((event) => {
    const eventActions = YEvent2BlockActions(backupDoc, event);

    if (eventActions.length === 0) return;

    actions.push(...eventActions);
  });

  return actions;
}

export function YEvent2BlockActions(
  backupDoc: Readonly<Y.Doc>,
  event: Y.YEvent<Y.XmlText>
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const { target: yXmlText, keys, delta, path } = event;
  const isBlockEvent = !!yXmlText.getAttribute('blockId');
  const sharedType = backupDoc.get('sharedType', Y.XmlText) as Readonly<Y.XmlText>;
  const rootId = sharedType.getAttribute('blockId');

  const backupTarget = getYTarget(backupDoc, path) as Readonly<Y.XmlText>;
  const actions = [];

  if (yXmlText.getAttribute('type') === 'text') {
    actions.push(...textOps2BlockActions(rootId, yXmlText, delta));
  }

  if (keys.size > 0) {
    actions.push(...dataOps2BlockActions(yXmlText, keys));
  }

  if (isBlockEvent) {
    actions.push(...blockOps2BlockActions(backupTarget, delta));
  }

  return actions;
}

function textOps2BlockActions(
  rootId: string,
  yXmlText: Y.XmlText,
  ops: YDelta
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  if (ops.length === 0) return [];
  const blockYXmlText = yXmlText.parent as Y.XmlText;
  const blockId = blockYXmlText.getAttribute('blockId');

  if (blockId === rootId) {
    return [];
  }

  return generateApplyTextActions(yXmlText, ops);
}

function dataOps2BlockActions(
  yXmlText: Y.XmlText,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  keys: Map<string, { action: 'update' | 'add' | 'delete'; oldValue: any; newValue: any }>
) {
  const dataUpdated = keys.has('data');

  if (!dataUpdated) return [];
  const data = yXmlText.getAttribute('data');

  return generateUpdateActions(yXmlText, {
    data,
  });
}

function blockOps2BlockActions(
  blockYXmlText: Readonly<Y.XmlText>,
  ops: YDelta
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const actions: ReturnType<typeof BlockActionPB.prototype.toObject>[] = [];

  let index = 0;

  let newOps = ops;

  if (ops.length > 1) {
    const [deleteOp, insertOp, ...otherOps] = newOps;

    const insert = insertOp.insert;

    if (deleteOp.delete === 1 && insert && insert instanceof Y.XmlText) {
      const textNode = getInsertTarget(blockYXmlText, [0]);
      const textId = textNode.getAttribute('textId');

      if (textId) {
        const length = textNode.length;

        insert.setAttribute('textId', textId);

        actions.push(
          ...generateApplyTextActions(insert, [
            {
              delete: length,
            },
            ...insert.toDelta(),
          ])
        );
      }

      newOps = [
        {
          retain: 1,
        },
        ...otherOps,
      ];
    }
  }

  newOps.forEach((op) => {
    if (op.insert) {
      if (op.insert instanceof Y.XmlText) {
        const insertYXmlText = op.insert;
        const blockId = insertYXmlText.getAttribute('blockId');
        const textId = insertYXmlText.getAttribute('textId');

        if (!blockId && !textId) {
          throw new Error('blockId and textId is not exist');
        }

        actions.push(...generateInsertBlockActions(insertYXmlText));
        index += 1;
      }
    } else if (op.retain) {
      index += op.retain;
    } else if (op.delete) {
      for (let i = index; i < op.delete + index; i++) {
        const target = getInsertTarget(blockYXmlText, [i]);

        if (target) {
          const deletedId = target.getAttribute('blockId') as string;

          if (deletedId) {
            actions.push(
              ...generateDeleteBlockActions({
                ids: [deletedId],
              })
            );
          }
        }
      }
    }
  });

  return actions;
}

export function generateUpdateActions(
  yXmlText: Y.XmlText,
  {
    data,
  }: {
    data?: Record<string, string | boolean>;
    external_id?: string;
  }
) {
  const id = yXmlText.getAttribute('blockId');
  const parentId = yXmlText.getAttribute('parentId');

  return [
    {
      action: BlockActionTypePB.Update,
      payload: {
        block: {
          id,
          data: JSON.stringify(data),
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

export function generateDeleteBlockActions({ ids }: { ids: string[] }) {
  return ids.map((id) => ({
    action: BlockActionTypePB.Delete,
    payload: {
      block: {
        id,
      },
      parent_id: '',
    },
  }));
}

export function generateInsertTextActions(insertYXmlText: Y.XmlText) {
  const textId = insertYXmlText.getAttribute('textId');
  const delta = YDelta2Delta(insertYXmlText.toDelta());

  return [
    {
      action: BlockActionTypePB.InsertText,
      payload: {
        text_id: textId,
        delta: JSON.stringify(delta),
      },
    },
  ];
}

export function generateInsertBlockActions(
  insertYXmlText: Y.XmlText
): ReturnType<typeof BlockActionPB.prototype.toObject>[] {
  const childrenId = generateId();
  const [textInsert, ...childrenInserts] = (insertYXmlText.toDelta() as YDelta).map((op) => op.insert);
  const textInsertActions = textInsert instanceof Y.XmlText ? generateInsertTextActions(textInsert) : [];
  const externalId = textInsertActions[0]?.payload.text_id;
  const prev = insertYXmlText.prevSibling;
  const prevId = prev ? prev.getAttribute('blockId') : null;
  const parentId = (insertYXmlText.parent as Y.XmlText).getAttribute('blockId');

  const data = insertYXmlText.getAttribute('data');
  const type = insertYXmlText.getAttribute('type');
  const id = insertYXmlText.getAttribute('blockId');

  if (!id) {
    Log.error('generateInsertBlockActions', 'id is not exist');
    return [];
  }

  if (!type || type === 'text' || Object.values(EditorNodeType).indexOf(type) === -1) {
    Log.error('generateInsertBlockActions', 'type is error: ' + type);
    return [];
  }

  const actions: ReturnType<typeof BlockActionPB.prototype.toObject>[] = [
    ...textInsertActions,
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
          external_type: externalId ? 'text' : undefined,
        },
        prev_id: prevId,
        parent_id: parentId,
      },
    },
  ];

  childrenInserts.forEach((insert) => {
    if (insert instanceof Y.XmlText) {
      actions.push(...generateInsertBlockActions(insert));
    }
  });

  return actions;
}
