import { createEditor, Descendant, Transforms } from 'slate';
import { ReactEditor, withReact } from 'slate-react';
import * as Y from 'yjs';
import { slateNodesToInsertDelta, withYjs, YjsEditor } from '@slate-yjs/core';
import { useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';

import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta, TextSelection } from '$app/interfaces/document';
import { NodeContext } from '../SubscribeNode.hooks';
import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { updateNodeDeltaThunk } from '$app_reducers/document/async-actions/blocks/text/update';
import { deltaToSlateValue } from '$app/utils/document/blocks/common';
import { documentActions } from '$app_reducers/document/slice';

import { isSameDelta } from '$app/utils/document/blocks/text/delta';

export function useTextInput(id: string) {
  const dispatch = useAppDispatch();
  const node = useContext(NodeContext);
  const selectionRef = useRef<TextSelection | null>(null);

  const delta = useMemo(() => {
    if (!node || !('delta' in node.data)) {
      return [];
    }
    return node.data.delta;
  }, [node]);

  const { editor, yText } = useBindYjs(id, delta);

  const [value, setValue] = useState<Descendant[]>([]);

  const storeSelection = useCallback(() => {
    if (!ReactEditor.isFocused(editor)) {
      selectionRef.current = null;
      return;
    }

    const selection = editor.selection as TextSelection;
    if (selectionRef.current && JSON.stringify(selection) !== JSON.stringify(selectionRef.current)) {
      Transforms.select(editor, selectionRef.current);
      selectionRef.current = null;
    }

    dispatch(documentActions.setTextSelection({ blockId: id, selection }));
  }, [dispatch, editor, id]);

  const currentSelection = useAppSelector((state) => state.document.textSelections[id]);
  const restoreSelection = useCallback(() => {
    if (!currentSelection) return;
    if (ReactEditor.isFocused(editor)) {
      Transforms.select(editor, currentSelection);
    } else {
      selectionRef.current = currentSelection;
      Transforms.select(editor, currentSelection);
      ReactEditor.focus(editor);
    }
  }, [currentSelection, editor]);

  const onChange = useCallback(
    (e: Descendant[]) => {
      setValue(e);
      storeSelection();
    },
    [storeSelection]
  );

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

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
    // It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
  }, []);

  return {
    editor,
    yText,
    onChange,
    value,
    onDOMBeforeInput,
  };
}
function useBindYjs(id: string, delta: TextDelta[]) {
  const { sendDelta } = useController(id);
  const yTextRef = useRef<Y.XmlText>();

  // Create a yjs document and get the shared type
  const sharedType = useMemo(() => {
    const doc = new Y.Doc();
    const _sharedType = doc.get('content', Y.XmlText) as Y.XmlText;

    const insertDelta = slateNodesToInsertDelta(deltaToSlateValue(delta));
    // Load the initial value into the yjs document
    _sharedType.applyDelta(insertDelta);

    const yText = insertDelta[0].insert as Y.XmlText;
    yTextRef.current = yText;

    return _sharedType;
    // Here we only want to create the sharedType once
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const editor = useMemo(() => withYjs(withReact(createEditor()), sharedType), []);

  useEffect(() => {
    YjsEditor.connect(editor);
    return () => {
      yTextRef.current = undefined;
      YjsEditor.disconnect(editor);
    };
  }, [editor]);

  useEffect(() => {
    const yText = yTextRef.current;
    if (!yText) return;
    const textEventHandler = (event: Y.YTextEvent) => {
      const textDelta = event.target.toDelta();
      void sendDelta(textDelta);
    };

    yText.observe(textEventHandler);
    return () => {
      yText.unobserve(textEventHandler);
    };
  }, [sendDelta]);

  useEffect(() => {
    const yText = yTextRef.current;
    if (!yText) return;

    // If the delta is not equal to the current yText, then we need to update the yText
    const isSame = isSameDelta(delta, yText.toDelta());
    if (isSame) return;

    yText.delete(0, yText.length);
    yText.applyDelta(delta);
  }, [delta, editor]);

  return { editor, yText: yTextRef.current };
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
