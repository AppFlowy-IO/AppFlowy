

import { useEffect, useMemo, useRef } from "react";
import { createEditor } from "slate";
import { withReact } from "slate-react";

import * as Y from 'yjs';
import { withYjs, YjsEditor, slateNodesToInsertDelta } from '@slate-yjs/core';
import { Delta } from '@slate-yjs/core/dist/model/types';
import { TextDelta } from '@/appflowy_app/interfaces/document';

const initialValue = [{
  type: 'paragraph',
  children: [{ text: '' }],
}];

export function useBindYjs(delta: TextDelta[], update: (_delta: TextDelta[]) => void) {
  const yTextRef = useRef<Y.XmlText>();
  // Create a yjs document and get the shared type
  const sharedType = useMemo(() => {
    const ydoc = new Y.Doc()
    const _sharedType = ydoc.get('content', Y.XmlText) as Y.XmlText;
    
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
    }
  }, [editor]);

  useEffect(() => {
    const yText = yTextRef.current;
    if (!yText) return;

    const textEventHandler = (event: Y.YTextEvent) => {
      update(event.changes.delta as TextDelta[]);
    }
    yText.applyDelta(delta);
    yText.observe(textEventHandler);
  
    return () => {
      yText.unobserve(textEventHandler);
    }
  }, [delta])
  

  return { editor }
}