import { useCallback, useContext, useMemo, useRef, useEffect } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta } from '$app/interfaces/document';
import { debounce } from '@/appflowy_app/utils/tool';
import { createEditor } from 'slate';
import { withReact } from 'slate-react';

import * as Y from 'yjs';
import { withYjs, YjsEditor, slateNodesToInsertDelta } from '@slate-yjs/core';

export function useTextInput(text: string, delta: TextDelta[]) {
  const { sendDelta } = useTransact(text);
  const { editor } = useBindYjs(delta, sendDelta);

  return {
    editor,
  };
}

function useController(textId: string) {
  const docController = useContext(DocumentControllerContext);

  const update = useCallback(
    (delta: TextDelta[]) => {
      docController?.yTextApply(textId, delta);
    },
    [textId]
  );
  const transact = useCallback(
    (actions: (() => void)[]) => {
      docController?.transact(actions);
    },
    [textId]
  );

  return {
    update,
    transact,
  };
}

function useTransact(textId: string) {
  const pendingActions = useRef<(() => void)[]>([]);
  const { update, transact } = useController(textId);

  const sendTransact = useCallback(() => {
    const actions = pendingActions.current;
    transact(actions);
  }, [transact]);

  const debounceSendTransact = useMemo(() => debounce(sendTransact, 300), [transact]);

  const sendDelta = useCallback(
    (delta: TextDelta[]) => {
      const action = () => update(delta);
      pendingActions.current.push(action);
      debounceSendTransact();
    },
    [update, debounceSendTransact]
  );
  return {
    sendDelta,
  };
}

const initialValue = [
  {
    type: 'paragraph',
    children: [{ text: '' }],
  },
];

export function useBindYjs(delta: TextDelta[], update: (_delta: TextDelta[]) => void) {
  const yTextRef = useRef<Y.XmlText>();
  // Create a yjs document and get the shared type
  const sharedType = useMemo(() => {
    const doc = new Y.Doc();
    const _sharedType = doc.get('content', Y.XmlText) as Y.XmlText;

    const insertDelta = slateNodesToInsertDelta(initialValue);
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
      update(event.changes.delta as TextDelta[]);
    };
    yText.applyDelta(delta);
    yText.observe(textEventHandler);

    return () => {
      yText.unobserve(textEventHandler);
    };
  }, [delta]);

  return { editor };
}
