import { createEditor, Descendant, Transforms, Element, Text, Editor } from 'slate';
import { ReactEditor, withReact } from 'slate-react';
import { useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';

import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta, TextSelection } from '$app/interfaces/document';
import { NodeContext } from '../SubscribeNode.hooks';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { updateNodeDeltaThunk } from '$app_reducers/document/async-actions/blocks/text/update';
import { deltaToSlateValue, getCollapsedRange, slateValueToDelta } from "$app/utils/document/blocks/common";
import { rangeSelectionActions } from "$app_reducers/document/slice";
import { getNodeEndSelection, isSameDelta } from '$app/utils/document/blocks/text/delta';

export function useTextInput(id: string) {
  const [editor] = useState(() => withReact(createEditor()));
  const node = useContext(NodeContext);
  const { sendDelta } = useController(id);
  const { storeSelection } = useSelection(id, editor);
  const isComposition = useRef(false);

  const delta = useMemo(() => {
    if (!node || !('delta' in node.data)) {
      return [];
    }
    return node.data.delta;
  }, [node]);
  const [value, setValue] = useState<Descendant[]>(deltaToSlateValue(delta));

  // Update the editor's value when the node's delta changes.
  useEffect(() => {
    // If composition is in progress, do nothing.
    if (isComposition.current) return;

    // If the delta is the same as the editor's value, do nothing.
    const localDelta = slateValueToDelta(editor.children);
    const isSame = isSameDelta(delta, localDelta);
    if (isSame) return;

    const slateValue = deltaToSlateValue(delta);
    editor.children = slateValue;
    setValue(slateValue);
  }, [delta, editor]);

  // Update the node's delta when the editor's value changes.
  const onChange = useCallback(
    (e: Descendant[]) => {
      // Update the editor's value and selection.
      setValue(e);
      storeSelection();

      // If composition is in progress, do nothing.
      if (isComposition.current) return;

      // Update the node's delta
      const textDelta = slateValueToDelta(e);
      void sendDelta(textDelta);
    },
    [sendDelta, storeSelection]
  );

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
    // It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
  }, []);

  const onCompositionStart = useCallback(() => {
    isComposition.current = true;
  }, []);

  const onCompositionUpdate = useCallback(() => {
    isComposition.current = true;
  }, []);

  const onCompositionEnd = useCallback(() => {
    isComposition.current = false;
  }, []);

  return {
    editor,
    onChange,
    value,
    onDOMBeforeInput,
    onCompositionStart,
    onCompositionUpdate,
    onCompositionEnd,
  };
}

function useController(id: string) {
  const docController = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();

  const sendDelta = useCallback(
    async (delta: TextDelta[]) => {
      if (!docController) return;
      await dispatch(
        updateNodeDeltaThunk({
          id,
          delta,
          controller: docController,
        })
      );
    },
    [dispatch, docController, id]
  );

  return {
    sendDelta,
  };
}

function useSelection(id: string, editor: ReactEditor) {
  const dispatch = useAppDispatch();
  const selectionRef = useRef<TextSelection | null>(null);
  const currentSelection = useAppSelector((state) => {
    const range = state.rangeSelection;
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
    storeSelection,
  };
}
