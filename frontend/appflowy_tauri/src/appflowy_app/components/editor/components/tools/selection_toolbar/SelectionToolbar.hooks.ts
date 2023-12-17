import { ReactEditor, useSlate } from 'slate-react';
import { MutableRefObject, useCallback, useEffect, useRef, useState } from 'react';
import { getSelectionPosition } from '$app/components/editor/components/tools/selection_toolbar/utils';
import debounce from 'lodash-es/debounce';

export function useSelectionToolbar(ref: MutableRefObject<HTMLDivElement | null>) {
  const editor = useSlate() as ReactEditor;

  const [visible, setVisible] = useState(false);
  const rangeRef = useRef<Range | null>(null);

  const recalculatePosition = useCallback(() => {
    const el = ref.current;

    if (!el) {
      return;
    }

    if (rangeRef.current) {
      return;
    }

    const position = getSelectionPosition(editor);

    if (!position) {
      rangeRef.current = null;
      setVisible(false);
      el.style.opacity = '0';
      el.style.pointerEvents = 'none';
      return;
    }

    const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

    setVisible(true);
    el.style.opacity = '1';
    el.style.pointerEvents = 'auto';
    el.style.top = `${position.top + slateEditorDom.offsetTop - el.offsetHeight}px`;
    el.style.left = `${position.left + slateEditorDom.offsetLeft - el.offsetWidth / 2 + position.width / 2}px`;
  }, [editor, ref]);

  useEffect(() => {
    const debounceRecalculatePosition = debounce(recalculatePosition, 100);

    document.addEventListener('mouseup', debounceRecalculatePosition);
    document.addEventListener('keydown', debounceRecalculatePosition);
    return () => {
      document.removeEventListener('mouseup', debounceRecalculatePosition);
      document.addEventListener('keydown', debounceRecalculatePosition);
    };
  }, [editor, recalculatePosition, ref]);

  const restoreSelection = useCallback(() => {
    if (!rangeRef.current) return;
    const windowSelection = window.getSelection();

    if (!windowSelection) return;
    windowSelection.removeAllRanges();
    windowSelection.addRange(rangeRef.current);
    rangeRef.current = null;
  }, []);

  const storeSelection = useCallback(() => {
    const windowSelection = window.getSelection();

    if (!windowSelection) return;

    if (windowSelection.rangeCount === 0) return;

    rangeRef.current = windowSelection.getRangeAt(0);
  }, []);

  return {
    visible,
    restoreSelection,
    storeSelection,
  };
}
