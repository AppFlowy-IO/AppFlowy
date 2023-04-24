import { useCallback, useContext, useMemo, useRef, useEffect, useState } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta } from '$app/interfaces/document';
import { NodeContext } from './SubscribeNode.hooks';
import { useAppDispatch, useAppSelector } from '@/appflowy_app/stores/store';

import { createEditor, Descendant, Transforms } from 'slate';
import { withReact, ReactEditor } from 'slate-react';

import * as Y from 'yjs';
import { withYjs, YjsEditor, slateNodesToInsertDelta } from '@slate-yjs/core';
import { updateNodeDeltaThunk } from '@/appflowy_app/stores/reducers/document/async_actions/update';
import { documentActions, TextSelection } from '@/appflowy_app/stores/reducers/document/slice';
import { deltaToSlateValue, getDeltaFromSlateNodes } from '@/appflowy_app/utils/block';

export function useTextInput(id: string) {
  const dispatch = useAppDispatch();
  const node = useContext(NodeContext);

  const delta = useMemo(() => {
    if (!node || !('delta' in node.data)) {
      return [];
    }
    return node.data.delta;
  }, [node?.data]);

  const { editor, yText } = useBindYjs(id, delta);

  useEffect(() => {
    return () => {
      dispatch(documentActions.removeTextSelection(id));
    };
  }, [id]);

  const [value, setValue] = useState<Descendant[]>([]);

  const onChange = useCallback((e: Descendant[]) => {
    setValue(e);
  }, []);

  const currentSelection = useAppSelector((state) => state.document.textSelections[id]);

  useEffect(() => {
    setSelection(editor, currentSelection);
  }, [editor, currentSelection]);

  if (editor.selection && ReactEditor.isFocused(editor)) {
    const domSelection = window.getSelection();
    // this is a hack to fix the issue where the selection is not in the dom
    if (domSelection?.rangeCount === 0) {
      const range = ReactEditor.toDOMRange(editor, editor.selection);
      domSelection.addRange(range);
    }
  }

  return {
    editor,
    yText,
    onChange,
    value,
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

  const currentSelection = useAppSelector((state) => state.document.textSelections[id]);

  useEffect(() => {
    const yText = yTextRef.current;
    if (!yText) return;

    // If the delta is not equal to the current yText, then we need to update the yText
    if (JSON.stringify(yText.toDelta()) !== JSON.stringify(delta)) {
      yText.delete(0, yText.length);
      yText.applyDelta(delta);
      // It should be noted that the selection will be lost after the yText is updated
      setSelection(editor, currentSelection);
    }
  }, [delta, currentSelection, editor]);

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
    [docController, id]
  );

  return {
    sendDelta,
  };
}

function setSelection(editor: ReactEditor, currentSelection: TextSelection) {
  // If the current selection is empty, blur the editor and deselect the selection
  if (!currentSelection || !currentSelection.anchor || !currentSelection.focus) {
    ReactEditor.blur(editor);
    ReactEditor.deselect(editor);
    return;
  }

  // If the editor is focused and the current selection is the same as the editor's selection, no need to set the selection
  if (ReactEditor.isFocused(editor) && JSON.stringify(currentSelection) === JSON.stringify(editor.selection)) {
    return;
  }

  const { path, offset } = currentSelection.focus;
  // It is possible that the current selection is out of range
  const children = getDeltaFromSlateNodes(editor.children);
  if (children[path[1]].insert.length < offset) {
    return;
  }

  // the order of the following two lines is important
  // if we reverse the order, the selection will be lost or always at the start
  Transforms.select(editor, currentSelection);
  editor.selection = currentSelection;
  ReactEditor.focus(editor);
}
