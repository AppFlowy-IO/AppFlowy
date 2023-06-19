import { Op } from 'quill-delta';
import { TextAction } from '$app/interfaces/document';

export function adaptDeltaForQuill(inputOps: Op[], isOutput = false): Op[] {
  if (inputOps.length === 0) {
    return inputOps;
  }

  // quill attribute -> custom attribute
  const attributeMapping = {
    strike: TextAction.Strikethrough,
  };

  const newOps = inputOps.map((op) => {
    if (!op.attributes) return op;
    const newOpAttributes = { ...op.attributes };

    Object.entries(attributeMapping).forEach(([attribute, customAttribute]) => {
      if (isOutput) {
        if (attribute in newOpAttributes) {
          newOpAttributes[customAttribute] = newOpAttributes[attribute];
          delete newOpAttributes[attribute];
        }
      } else {
        if (customAttribute in newOpAttributes) {
          newOpAttributes[attribute] = newOpAttributes[customAttribute];
          delete newOpAttributes[customAttribute];
        }
      }
    });

    return {
      ...op,
      attributes: newOpAttributes,
    };
  });

  const lastOpIndex = newOps.length - 1;
  const lastOp = newOps[lastOpIndex];
  const text = lastOp.insert as string;
  const endsWithNewline = text.endsWith('\n');

  if (isOutput && !endsWithNewline) {
    return newOps;
  }

  if (isOutput) {
    const newText = text.slice(0, -1);
    if (newText !== '') {
      newOps[lastOpIndex] = { ...lastOp, insert: newText };
    } else {
      newOps.pop();
    }
  } else {
    newOps.push({ insert: '\n' });
  }

  return newOps;
}
