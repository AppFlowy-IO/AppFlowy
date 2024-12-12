import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { getSelectionPosition } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import { Decorate, useEditorContext } from '@/components/editor/EditorContext';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { debounce } from 'lodash-es';
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { Range } from 'slate';
import { ReactEditor, useFocused, useSlate, useSlateStatic } from 'slate-react';

export function useVisible() {
  const editor = useSlate();
  const selection = editor.selection;
  const { decorateState, addDecorate, removeDecorate } = useEditorContext();
  const [forceShow, setForceShow] = useState<boolean>(false);
  const [isDragging, setDragging] = useState<boolean>(false);

  const focus = useFocused();

  const isExpanded = selection ? Range.isExpanded(selection) : false;

  const selectedText = selection ? editor.string(selection, {
    voids: true,
  }) : '';

  const visible = useMemo(() => {
    if (forceShow) return true;
    if (!focus) return false;

    if (document.getSelection()?.isCollapsed) return false;

    const show = Boolean(selectedText && isExpanded && !isDragging);

    return show;
  }, [forceShow, focus, selectedText, isExpanded, isDragging]);

  useEffect(() => {
    if (!visible) {
      removeDecorate?.('selection-toolbar');
      return;
    }

  }, [visible, removeDecorate]);

  useEffect(() => {

    const handleMouseDown = () => {
      const { selection } = editor;

      if (selection && Range.isExpanded(selection)) {
        window.getSelection()?.removeAllRanges();
      }

      setDragging(true);
    };

    const handleMouseUp = () => {
      setDragging(false);
      setForceShow(false);
      removeDecorate?.('selection-toolbar');
    };

    document.addEventListener('mousedown', handleMouseDown);

    document.addEventListener('mouseup', handleMouseUp);

    return () => {
      document.removeEventListener('mousedown', handleMouseDown);

      document.removeEventListener('mouseup', handleMouseUp);
    };

  }, [editor, removeDecorate]);

  const handleForceShow = useCallback((show: boolean) => {
    if (show && editor.selection) {
      setForceShow(true);
      addDecorate?.(editor.selection, 'bg-content-blue-100', 'selection-toolbar');
    } else {
      setForceShow(false);
    }
  }, [addDecorate, editor]);

  const getDecorateState = useCallback(() => {
    return decorateState?.['selection-toolbar'];
  }, [decorateState]);

  useEffect(() => {
    if (!visible) return;
    const handleKeyDown = (event: KeyboardEvent) => {

      switch (true) {
        case createHotkey(HOT_KEY_NAME.ESCAPE)(event): {
          if (!editor.selection) break;
          event.preventDefault();
          event.stopPropagation();
          const start = editor.start(editor.selection);

          editor.select(start);
          ReactEditor.focus(editor);

          break;
        }

        /**
         * Bold: Mod + B
         */
        case createHotkey(HOT_KEY_NAME.BOLD)(event):
          event.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Bold,
            value: true,
          });
          break;
        /**
         * Italic: Mod + I
         */
        case createHotkey(HOT_KEY_NAME.ITALIC)(event):
          event.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Italic,
            value: true,
          });
          break;
        /**
         * Underline: Mod + U
         */
        case createHotkey(HOT_KEY_NAME.UNDERLINE)(event):
          event.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Underline,
            value: true,
          });
          break;
        /**
         * Strikethrough: Mod + Shift + S / Mod + Shift + X
         */
        case createHotkey(HOT_KEY_NAME.STRIKETHROUGH)(event):
          event.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.StrikeThrough,
            value: true,
          });
          break;
        /**
         * Code: Mod + E
         */
        case createHotkey(HOT_KEY_NAME.CODE)(event):
          event.preventDefault();
          CustomEditor.toggleMark(editor, {
            key: EditorMarkFormat.Code,
            value: true,
          });
          break;
        /**
         * Highlight: Mod + Shift + H
         */
        case createHotkey(HOT_KEY_NAME.HIGH_LIGHT)(event):
          event.preventDefault();
          CustomEditor.highlight(editor);
          break;
      }
    };

    const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

    slateEditorDom.addEventListener('keydown', handleKeyDown);

    return () => {
      slateEditorDom.removeEventListener('keydown', handleKeyDown);
    };
  }, [editor, visible]);

  return {
    visible,
    forceShow: handleForceShow,
    getDecorateState,
  };

}

export function useToolbarPosition() {
  const editor = useSlateStatic();

  const setPosition = useCallback((toolbarEl: HTMLDivElement, position: {
    top: number,
    left: number,
    width: number,
    height: number
  }) => {
    const slateEditorDom = ReactEditor.toDOMNode(editor, editor);

    toolbarEl.style.top = `${position.top + slateEditorDom.offsetTop - toolbarEl.offsetHeight}px`;
    const left = position.left + slateEditorDom.offsetLeft;

    // If toolbar is out of editor, move it to the left edge of the editor
    if (left <= 0) {
      toolbarEl.style.left = '0px';
      return;
    }

    const right = left + toolbarEl.offsetWidth;
    const rightBound = slateEditorDom.offsetWidth + slateEditorDom.offsetLeft;

    // If toolbar is out of editor, move the right edge to the right edge of the editor
    if (right > rightBound) {
      toolbarEl.style.left = `${rightBound - toolbarEl.offsetWidth}px`;
      return;
    }

    toolbarEl.style.left = `${left}px`;
  }, [editor]);

  const showToolbar = useCallback((toolbarEl: HTMLDivElement) => {
    const position = getSelectionPosition(editor);

    if (position) {
      toolbarEl.style.opacity = '1';
      toolbarEl.style.pointerEvents = 'auto';
      setPosition(toolbarEl, position);
    }
  }, [editor, setPosition]);
  const debounceShow = useMemo(() => debounce(showToolbar, 50), [showToolbar]);
  const hideToolbar = useCallback((toolbarEl: HTMLDivElement) => {
    debounceShow.cancel();
    toolbarEl.style.opacity = '0';
    toolbarEl.style.pointerEvents = 'none';
  }, [debounceShow]);

  return {
    showToolbar: debounceShow,
    hideToolbar,
  };
}

export const SelectionToolbarContext = createContext<{
  visible: boolean;
  forceShow: (forceVisible: boolean) => void;
  rePosition: () => void;
  getDecorateState: () => Decorate | undefined;
}>({
  visible: false,
  forceShow: () => undefined,
  rePosition: () => undefined,
  getDecorateState: () => undefined,
});

export function useSelectionToolbarContext() {
  return useContext(SelectionToolbarContext);
}
