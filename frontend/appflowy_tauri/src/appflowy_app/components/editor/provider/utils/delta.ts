import { YDelta, YOp } from '$app/components/editor/provider/types/y_event';
import { Op } from 'quill-delta';
import * as Y from 'yjs';
import { inlineNodeTypes } from '$app/application/document/document.types';
import { DocEventPB } from '@/services/backend';

export function YDelta2Delta(yDelta: YDelta): Op[] {
  return yDelta.map((op) => {
    if (op.insert instanceof Y.XmlText) {
      const type = op.insert.getAttribute('type');

      if (inlineNodeTypes.includes(type)) {
        return YInlineOp2Op(op);
      }
    }

    return op as Op;
  });
}

export function YInlineOp2Op(yOp: YOp): Op {
  if (!(yOp.insert instanceof Y.XmlText)) return yOp as Op;

  const type = yOp.insert.getAttribute('type');
  const data = yOp.insert.getAttribute('data');

  return {
    insert: yOp.insert.toJSON(),
    attributes: {
      [type]: data,
    },
  };
}

export function DocEvent2YDelta(events: DocEventPB): YDelta {
  if (!events.is_remote) return [];

  return [];
}
