import { ReactEditor } from "slate-react";
import { useAppDispatch, useAppSelector } from "$app/stores/store";
import { useCallback, useEffect, useRef } from "react";
import { TextSelection } from "$app/interfaces/document";
import { Editor, Element, Text, Transforms } from "slate";
import { getNodeEndSelection } from "$app/utils/document/blocks/text/delta";
import { getCollapsedRange, slateValueToDelta } from "$app/utils/document/blocks/common";
import { rangeSelectionActions } from "$app_reducers/document/slice";

export function useSelection(id: string, editor: ReactEditor) {
  const dispatch = useAppDispatch();
  const selectionRef = useRef<TextSelection | null>(null);
  const currentSelection = useAppSelector((state) => {
    const range = state.documentRangeSelection;
    if (!range.anchor || !range.focus) return null;
    if (range.anchor.id === id) {
      return range.anchor.selection;
    }
    if (range.focus.id === id) {
      return range.focus.selection;
    }
    return null;
  });

  // whether the selection is out of range.
  const outOfRange = useCallback(
    (selection: TextSelection) => {
      const point = Editor.end(editor, selection);
      const { path, offset } = point;
      // path length is 2, because the editor is a single text node.
      const [i, j] = path;
      const children = editor.children[i] as Element;
      if (!children) return true;
      const child = children.children[j] as Text;
      return child.text.length < offset;
    },
    [editor]
  );

  // store the selection
  const storeSelection = useCallback(() => {
    // do nothing if the node is not focused.
    if (!ReactEditor.isFocused(editor)) {
      selectionRef.current = null;
      return;
    }
    // set selection to the end of the node if the selection is out of range.
    if (outOfRange(editor.selection as TextSelection)) {
      editor.selection = getNodeEndSelection(slateValueToDelta(editor.children));
      selectionRef.current = null;
    }

    let selection = editor.selection as TextSelection;
    // the selection will sometimes be cleared after the editor is focused.
    // so we need to restore the selection when selection ref is not null.
    if (selectionRef.current && JSON.stringify(editor.selection) !== JSON.stringify(selectionRef.current)) {
      Transforms.select(editor, selectionRef.current);
      selection = selectionRef.current;
    }
    selectionRef.current = null;
    const range = getCollapsedRange(id, selection);
    dispatch(rangeSelectionActions.setRange(range));
  }, [dispatch, editor, id, outOfRange]);


  // restore the selection
  const restoreSelection = useCallback((selection: TextSelection | null) => {
    if (!selection) return;
    // do nothing if the selection is out of range
    if (outOfRange(selection)) return;

    if (ReactEditor.isFocused(editor)) {
      // if the editor is focused, set the selection directly.
      if (JSON.stringify(selection) === JSON.stringify(editor.selection)) return;
      Transforms.select(editor, selection);
    } else {
      // Here we store the selection in the ref,
      // because the selection will sometimes be cleared after the editor is focused.
      selectionRef.current = selection;
      Transforms.select(editor, selection);
      ReactEditor.focus(editor);
    }
  }, [editor, outOfRange]);

  useEffect(() => {
    restoreSelection(currentSelection);
  }, [restoreSelection, currentSelection]);

  if (editor.selection && ReactEditor.isFocused(editor)) {
    const domSelection = window.getSelection();
    // this is a hack to fix the issue where the selection is not in the dom
    if (domSelection?.rangeCount === 0) {
      const range = ReactEditor.toDOMRange(editor, editor.selection);
      domSelection.addRange(range);
    }
  }

  return {
    storeSelection
  };
}