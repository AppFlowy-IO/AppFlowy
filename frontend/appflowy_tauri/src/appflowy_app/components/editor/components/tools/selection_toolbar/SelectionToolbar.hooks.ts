import { ReactEditor, useFocused, useSlate } from 'slate-react';
import { MutableRefObject, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { getSelectionPosition } from '$app/components/editor/components/tools/selection_toolbar/utils';
import debounce from 'lodash-es/debounce';
import { CustomEditor } from '$app/components/editor/command';
import { BaseRange, Editor, Range as SlateRange } from 'slate';
import { useDecorateDispatch } from '$app/components/editor/stores/decorate';

const DELAY = 300;

export function useSelectionToolbar(ref: MutableRefObject<HTMLDivElement | null>) {
  const editor = useSlate() as ReactEditor;
  const isDraggingRef = useRef(false);
  const [isAcrossBlocks, setIsAcrossBlocks] = useState(false);
  const [visible, setVisible] = useState(false);
  const isFocusedEditor = useFocused();

  // paint the selection when the editor is blurred
  const { add: addDecorate, clear: clearDecorate, getStaticState } = useDecorateDispatch();

  // Restore selection after the editor is focused
  const restoreSelection = useCallback(() => {
    const decorateState = getStaticState();

    if (!decorateState) return;

    editor.select({
      ...decorateState.range,
    });

    clearDecorate();
    ReactEditor.focus(editor);
  }, [getStaticState, clearDecorate, editor]);

  // Store selection when the editor is blurred
  const storeSelection = useCallback(() => {
    addDecorate({
      range: editor.selection as BaseRange,
      class_name: 'bg-content-blue-100',
    });
  }, [addDecorate, editor]);

  const closeToolbar = useCallback(() => {
    const el = ref.current;

    if (!el) {
      return;
    }

    restoreSelection();

    setVisible(false);
    el.style.opacity = '0';
    el.style.pointerEvents = 'none';
  }, [ref, restoreSelection]);

  const recalculatePosition = useCallback(() => {
    const el = ref.current;

    if (!el) {
      return;
    }

    // Close toolbar when selection include root
    if (CustomEditor.selectionIncludeRoot(editor)) {
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

    // if dragging, disable pointer events
    if (isDraggingRef.current) {
      el.style.pointerEvents = 'none';
    } else {
      el.style.pointerEvents = 'auto';
    }

    // If toolbar is out of editor, move it to the top
    el.style.top = `${position.top + slateEditorDom.offsetTop - el.offsetHeight}px`;

    const left = position.left + slateEditorDom.offsetLeft;

    // If toolbar is out of editor, move it to the left edge of the editor
    if (left < 0) {
      el.style.left = '0';
      return;
    }

    const right = left + el.offsetWidth;

    // If toolbar is out of editor, move the right edge to the right edge of the editor
    if (right > slateEditorDom.offsetWidth) {
      el.style.left = `${slateEditorDom.offsetWidth - el.offsetWidth}px`;
      return;
    }

    el.style.left = `${left}px`;
  }, [closeToolbar, editor, ref]);

  const debounceRecalculatePosition = useMemo(() => debounce(recalculatePosition, DELAY), [recalculatePosition]);

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => {
    const decorateState = getStaticState();

    if (decorateState) return;

    const { selection } = editor;

    if (!isFocusedEditor || !selection || SlateRange.isCollapsed(selection) || Editor.string(editor, selection) === '') {
      debounceRecalculatePosition.cancel();
      closeToolbar();
      return;
    }

    const start = selection.anchor;
    const end = selection.focus;

    setIsAcrossBlocks(!CustomEditor.blockEqual(editor, start, end));
    debounceRecalculatePosition();
  });

  // Update drag status
  useEffect(() => {
    const el = ReactEditor.toDOMNode(editor, editor);

    const toolbar = ref.current;

    if (!el || !toolbar) {
      return;
    }

    const onMouseDown = () => {
      isDraggingRef.current = true;
    };

    const onMouseUp = () => {
      if (visible) {
        toolbar.style.pointerEvents = 'auto';
      }

      isDraggingRef.current = false;
    };

    el.addEventListener('mousedown', onMouseDown);
    document.addEventListener('mouseup', onMouseUp);

    return () => {
      el.removeEventListener('mousedown', onMouseDown);
      document.removeEventListener('mouseup', onMouseUp);
    };
  }, [visible, editor, ref]);

  useEffect(() => {
    const slateEditorDom = ReactEditor.toDOMNode(editor, editor);
    const onKeyDown = (e: KeyboardEvent) => {
      // Close toolbar when press ESC
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        editor.collapse({
          edge: 'end',
        });
        debounceRecalculatePosition.cancel();
        closeToolbar();
      }
    };

    if (visible) {
      slateEditorDom.addEventListener('keydown', onKeyDown);
    } else {
      slateEditorDom.removeEventListener('keydown', onKeyDown);
    }

    return () => {
      slateEditorDom.removeEventListener('keydown', onKeyDown);
    };
  }, [closeToolbar, debounceRecalculatePosition, editor, visible]);

  return {
    visible,
    restoreSelection,
    storeSelection,
    isAcrossBlocks,
  };
}
