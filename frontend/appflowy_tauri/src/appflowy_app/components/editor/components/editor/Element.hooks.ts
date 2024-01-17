import { Element } from 'slate';
import { useContext, useEffect, useMemo } from 'react';
import { EditorSelectedBlockContext } from '$app/components/editor/components/editor/Editor.hooks';
import { useSnapshot } from 'valtio';
import { useSelected, useSlateStatic } from 'slate-react';

export function useElementState(element: Element) {
  const blockId = element.blockId;
  const editor = useSlateStatic();
  const selectedBlockContext = useContext(EditorSelectedBlockContext);
  const selected = useSelected();

  useEffect(() => {
    if (!blockId) return;
    if (selected && !editor.isSelectable(element)) {
      selectedBlockContext.add(blockId);
    } else {
      selectedBlockContext.delete(blockId);
    }
  }, [blockId, editor, element, selected, selectedBlockContext]);

  const selectedBlockIds = useSnapshot(selectedBlockContext);
  const isSelected = useMemo(() => {
    if (!blockId) return false;
    return selectedBlockIds.has(blockId);
  }, [blockId, selectedBlockIds]);

  return {
    isSelected,
  };
}
