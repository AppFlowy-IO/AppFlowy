import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useCallback, useEffect, useState } from 'react';
import Delta, { Op } from 'quill-delta';
import { useDelta } from '$app/components/document/_shared/EditorHooks/useDelta';

export function useChange(node: NestedBlock<BlockType.TextBlock | BlockType.CodeBlock>) {
  const { update, delta } = useDelta({ id: node.id });

  const [value, setValue] = useState<Delta>(() => {
    return delta;
  });

  useEffect(() => {
    setValue(delta);
  }, [delta]);

  const onChange = useCallback(
    async (ops: Op[], newDelta: Delta) => {
      if (ops.length === 0) return;
      setValue(newDelta);
      await update(ops, newDelta);
    },
    [update]
  );

  return {
    value,
    onChange,
  };
}
