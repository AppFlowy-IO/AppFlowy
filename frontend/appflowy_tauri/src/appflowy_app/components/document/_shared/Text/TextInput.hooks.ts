import { createEditor, Descendant, Transforms, Element, Text, Editor } from 'slate';
import { ReactEditor, withReact } from 'slate-react';
import { CompositionEvent, useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';

import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta, TextSelection } from '$app/interfaces/document';
import { NodeContext } from '../SubscribeNode.hooks';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { updateNodeDeltaThunk } from '$app_reducers/document/async-actions/blocks/text/update';
import { deltaToSlateValue, slateValueToDelta } from '$app/utils/document/blocks/common';
import { documentActions } from '$app_reducers/document/slice';
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

  useEffect(() => {
    if (isComposition.current) return;
    const localDelta = slateValueToDelta(editor.children);
    const isSame = isSameDelta(delta, localDelta);
    if (isSame) return;
    const slateValue = deltaToSlateValue(delta);
    editor.children = slateValue;
    setValue(slateValue);
  }, [delta, editor]);

  const onChange = useCallback(
    (e: Descendant[]) => {
      setValue(e);
      storeSelection();
      if (isComposition.current) return;
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

  const onCompositionStart = useCallback((e: CompositionEvent<HTMLDivElement>) => {
    isComposition.current = true;
  }, []);

  const onCompositionUpdate = useCallback((e: CompositionEvent<HTMLDivElement>) => {
    isComposition.current = true;
  }, []);

  const onCompositionEnd = useCallback((e: CompositionEvent<HTMLDivElement>) => {
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

  const storeSelection = useCallback(() => {
    if (!ReactEditor.isFocused(editor)) {
      selectionRef.current = null;
      return;
    }
    if (outOfRange(editor.selection as TextSelection)) {
      editor.selection = getNodeEndSelection(slateValueToDelta(editor.children));
      selectionRef.current = null;
    }
    const selection = editor.selection as TextSelection;
    if (selectionRef.current && JSON.stringify(selection) !== JSON.stringify(selectionRef.current)) {
      Transforms.select(editor, selectionRef.current);
      selectionRef.current = null;
    }

    dispatch(documentActions.setTextSelection({ blockId: id, selection }));
  }, [dispatch, editor, id, outOfRange]);

  const currentSelection = useAppSelector((state) => state.document.textSelections[id]);
  const restoreSelection = useCallback(() => {
    if (!currentSelection) return;
    // do nothing if the selection is out of range
    if (outOfRange(currentSelection)) return;

    if (ReactEditor.isFocused(editor)) {
      if (JSON.stringify(currentSelection) === JSON.stringify(editor.selection)) return;
      Transforms.select(editor, currentSelection);
    } else {
      selectionRef.current = currentSelection;
      Transforms.select(editor, currentSelection);
      ReactEditor.focus(editor);
    }
  }, [currentSelection, editor, outOfRange]);

  useEffect(() => {
    restoreSelection();
    return () => {
      dispatch(documentActions.removeTextSelection(id));
    };
  }, [dispatch, id, restoreSelection]);

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
