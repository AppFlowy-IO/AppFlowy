import { YDelta, YOp } from '$app/components/editor/provider/types/y_event';
import { Op } from 'quill-delta';
import * as Y from 'yjs';
import { inlineNodeTypes } from '$app/application/document/document.types';
import { DocEventPB } from '@/services/backend';

export function YDelta2Delta(yDelta: YDelta): Op[] {
  const ops: Op[] = [];

  yDelta.forEach((op) => {
    if (op.insert instanceof Y.XmlText) {
      const type = op.insert.getAttribute('type');

      if (inlineNodeTypes.includes(type)) {
        ops.push(...YInlineOp2Op(op));
        return;
      }
    }

    ops.push(op as Op);
  });
  return ops;
}

export function YInlineOp2Op(yOp: YOp): Op[] {
  if (!(yOp.insert instanceof Y.XmlText)) {
    return [
      {
        insert: yOp.insert as string,
        attributes: yOp.attributes,
      },
    ];
  }

  const type = yOp.insert.getAttribute('type');
  const data = yOp.insert.getAttribute('data');

  const delta = yOp.insert.toDelta() as Op[];

  return delta.map((op) => ({
    insert: op.insert,

    attributes: {
      [type]: data,
      ...op.attributes,
    },
  }));
}

export function DocEvent2YDelta(events: DocEventPB): YDelta {
  if (!events.is_remote) return [];

  return [];
}
