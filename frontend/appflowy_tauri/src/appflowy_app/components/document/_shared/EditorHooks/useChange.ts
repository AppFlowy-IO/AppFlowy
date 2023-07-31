import { BlockType, NestedBlock } from '$app/interfaces/document';
import { useCallback, useEffect, useState } from 'react';
import Delta from 'quill-delta';
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
    (newContents: Delta, oldContents: Delta, _source?: string) => {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      const isSame = newContents.diff(oldContents).ops.length === 0;
      if (isSame) return;
      setValue(newContents);
      update(newContents);
    },
    [update]
  );

  return {
    value,
    onChange,
  };
}
