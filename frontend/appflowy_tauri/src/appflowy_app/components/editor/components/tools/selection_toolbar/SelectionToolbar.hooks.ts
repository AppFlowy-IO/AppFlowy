import { ReactEditor, useSlate } from 'slate-react';
import { MutableRefObject, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { getSelectionPosition } from '$app/components/editor/components/tools/selection_toolbar/utils';
import debounce from 'lodash-es/debounce';
import { CustomEditor } from '$app/components/editor/command';
import { DecorateStateContext } from '$app/components/editor/components/editor/Editor.hooks';
import { BaseRange } from 'slate';

export function useSelectionToolbar(ref: MutableRefObject<HTMLDivElement | null>) {
  const editor = useSlate() as ReactEditor;

  const [visible, setVisible] = useState(false);
  const rangeRef = useRef<Range | null>(null);

  const closeToolbar = useCallback(() => {
    const el = ref.current;

    if (!el) {
      return;
    }

    rangeRef.current = null;
    setVisible(false);
    el.style.opacity = '0';
    el.style.pointerEvents = 'none';
  }, [ref]);

  const recalculatePosition = useCallback(() => {
    const el = ref.current;

    if (!el) {
      return;
    }

    if (CustomEditor.selectionIncludeRoot(editor)) {
      closeToolbar();
      return;
    }

    if (rangeRef.current) {
      closeToolbar();
      return;
    }

    const position = getSelectionPosition(editor);

    if (!position) {
      closeToolbar();
      return;
    }

    const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

    setVisible(true);
    el.style.opacity = '1';
    el.style.pointerEvents = 'auto';
    el.style.top = `${position.top + slateEditorDom.offsetTop - el.offsetHeight}px`;

    const left = position.left + slateEditorDom.offsetLeft - el.offsetWidth / 2 + position.width / 2;

    if (left < 0) {
      el.style.left = '0';
      return;
    }

    const right = left + el.offsetWidth;

    if (right > slateEditorDom.offsetWidth) {
      el.style.left = `${slateEditorDom.offsetWidth - el.offsetWidth}px`;
      return;
    }

    el.style.left = `${left}px`;
  }, [closeToolbar, editor, ref]);

  useEffect(() => {
    const debounceRecalculatePosition = debounce(recalculatePosition, 100);

    document.addEventListener('mouseup', debounceRecalculatePosition);
    document.addEventListener('keydown', debounceRecalculatePosition);
    return () => {
      document.removeEventListener('mouseup', debounceRecalculatePosition);
      document.addEventListener('keydown', debounceRecalculatePosition);
    };
  }, [editor, recalculatePosition, ref]);

  const decorateStateContext = useContext(DecorateStateContext);

  const restoreSelection = useCallback(() => {
    if (!rangeRef.current) return;
    const windowSelection = window.getSelection();

    if (!windowSelection) return;
    windowSelection.removeAllRanges();
    windowSelection.addRange(rangeRef.current);
    rangeRef.current = null;
    decorateStateContext.clear();
  }, [decorateStateContext]);

  const storeSelection = useCallback(() => {
    decorateStateContext.add({
      range: editor.selection as BaseRange,
      class_name: 'bg-content-blue-100',
    });
    const windowSelection = window.getSelection();

    if (!windowSelection) return;

    if (windowSelection.rangeCount === 0) return;

    rangeRef.current = windowSelection.getRangeAt(0);
  }, [decorateStateContext, editor.selection]);

  return {
    visible,
    restoreSelection,
    storeSelection,
  };
}
