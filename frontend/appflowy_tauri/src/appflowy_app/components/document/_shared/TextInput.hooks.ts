import { useCallback, useContext, useMemo, useRef, useEffect } from 'react';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta, BlockActionType } from '$app/interfaces/document';
import { debounce } from '@/appflowy_app/utils/tool';
import { createEditor } from 'slate';
import { withReact } from 'slate-react';

import * as Y from 'yjs';
import { withYjs, YjsEditor, slateNodesToInsertDelta } from '@slate-yjs/core';
import { NodeContext } from './SubscribeNode.hooks';
import { BlockActionTypePB } from '@/services/backend/models/flowy-document2';

export function useTextInput(delta: TextDelta[]) {
  const { sendDelta } = useTransact();
  const { editor } = useBindYjs(delta, sendDelta);

  return {
    editor,
  };
}

function useController() {
  const docController = useContext(DocumentControllerContext);
  const node = useContext(NodeContext);

  const update = useCallback(
    async (delta: TextDelta[]) => {
      if (!docController || !node) return;
      await docController.applyActions([
        {
          action: BlockActionTypePB.Update,
          payload: {
            block: {
              id: node.id,
              ty: node.type,
              parent_id: node.parent || '',
              children_id: node.children,
              data: JSON.stringify({
                ...node.data,
                delta,
              }),
            },
          },
        },
      ]);
    },
    [docController, node]
  );

  return {
    update,
  };
}

function useTransact() {
  const { update } = useController();

  const sendDelta = useCallback(
    (delta: TextDelta[]) => {
      void update(delta);
    },
    [update]
  );
  const debounceSendDelta = useMemo(() => debounce(sendDelta, 300), [sendDelta]);

  return {
    sendDelta: debounceSendDelta,
  };
}

const initialValue = [
  {
    type: 'paragraph',
    children: [{ text: '' }],
  },
];

function useBindYjs(delta: TextDelta[], update: (_delta: TextDelta[]) => void) {
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
      const textDelta = event.target.toDelta();
      update(textDelta);
    };
    yText.applyDelta(delta);
    yText.observe(textEventHandler);

    return () => {
      yText.unobserve(textEventHandler);
    };
  }, [delta]);

  return { editor };
}
