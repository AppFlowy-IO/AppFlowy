import { Element } from 'slate';
import { useContext, useEffect, useMemo } from 'react';
import { useSnapshot } from 'valtio';
import { useSelected } from 'slate-react';

import { EditorSelectedBlockContext } from '$app/components/editor/stores/selected';

export function useElementState(element: Element) {
  const blockId = element.blockId;
  const selectedBlockContext = useContext(EditorSelectedBlockContext);
  const selected = useSelected();

  useEffect(() => {
    if (!blockId) return;

    if (!selected) {
      selectedBlockContext.delete(blockId);
    }
  }, [blockId, selected, selectedBlockContext]);

  const selectedBlockIds = useSnapshot(selectedBlockContext);
  const blockSelected = useMemo(() => {
    if (!blockId) return false;
    return selectedBlockIds.has(blockId);
  }, [blockId, selectedBlockIds]);

  return {
    blockSelected,
  };
}
