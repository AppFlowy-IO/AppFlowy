import { YjsEditor } from '@/application/slate-yjs';
import { getOffsetPointFromSlateRange } from '@/application/slate-yjs/utils/yjsOperations';
import { getRangeRect, getSelectionPosition } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import { useEditorContext } from '@/components/editor/EditorContext';
import { PopoverPosition } from '@mui/material';
import { debounce } from 'lodash-es';
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';
import { Range } from 'slate';
import { ReactEditor, useFocused, useSlate, useSlateStatic } from 'slate-react';

export function useVisible () {
  const editor = useSlate();
  const selection = editor.selection;
  const { addDecorate, removeDecorate } = useEditorContext();
  const [forceShow, setForceShow] = useState<boolean>(false);
  const [isDragging, setDragging] = useState<boolean>(false);

  const focus = useFocused();

  const isExpanded = selection ? Range.isExpanded(selection) : false;

  const visible = useMemo(() => {
    if (forceShow) return true;
    if (!focus) return false;

    return isExpanded && !isDragging;
  }, [focus, forceShow, isExpanded, isDragging]);

  useEffect(() => {
    if (!visible) {
      removeDecorate?.('selection-toolbar');
      return;
    }

  }, [visible, removeDecorate]);

  useEffect(() => {

    const handleMouseDown = () => {
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

  }, [removeDecorate]);

  const handleForceShow = useCallback((show: boolean) => {
    if (show && editor.selection) {
      setForceShow(true);
      addDecorate?.(editor.selection, 'bg-content-blue-100', 'selection-toolbar');
    } else {
      setForceShow(false);
    }
  }, [addDecorate, editor.selection]);

  return {
    visible,
    forceShow: handleForceShow,
  };

}

export function useToolbarPosition () {
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
    if (left < 0) {
      toolbarEl.style.left = '0';
      return;
    }

    const right = left + toolbarEl.offsetWidth;

    // If toolbar is out of editor, move the right edge to the right edge of the editor
    if (right > slateEditorDom.offsetWidth) {
      toolbarEl.style.left = `${slateEditorDom.offsetWidth - toolbarEl.offsetWidth}px`;
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
}>({
  visible: false,
  forceShow: () => undefined,
});

export function useSelectionToolbarContext () {
  return useContext(SelectionToolbarContext);
}

interface RelativeRange {
  offset: number;
  textId: string;
}

export function useToolbarPopover (editor: YjsEditor) {
  const { forceShow } = useSelectionToolbarContext();
  const [anchorPosition, setAnchorPosition] = useState<PopoverPosition | undefined>(undefined);
  const rangeRef = useRef<{ start: RelativeRange; end: RelativeRange } | null>(null);

  const open = Boolean(anchorPosition);

  const handleClose = useCallback(() => {
    setAnchorPosition(undefined);
    forceShow(false);
  }, [forceShow]);

  const openPopover = useCallback(() => {
    if (!editor.selection) return;
    const rect = getRangeRect();

    if (!rect) return;

    try {
      rangeRef.current = {
        start: getOffsetPointFromSlateRange(editor, editor.start(editor.selection)),
        end: getOffsetPointFromSlateRange(editor, editor.end(editor.selection)),
      };
    } catch (e) {
      rangeRef.current = null;
    }

    forceShow(true);

    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left + rect.width / 2,
    });
  }, [editor, forceShow]);

  return {
    open,
    anchorPosition,
    handleClose,
    openPopover,
  };
}