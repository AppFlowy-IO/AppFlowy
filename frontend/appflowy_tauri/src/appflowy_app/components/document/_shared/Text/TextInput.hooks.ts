import { createEditor, Descendant, Editor, Transforms } from 'slate';
import { withReact } from 'slate-react';
import { useCallback, useContext, useEffect, useMemo, useRef, useState } from 'react';

import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta } from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { updateNodeDeltaThunk } from '$app_reducers/document/async-actions/blocks/text/update';
import { deltaToSlateValue, slateValueToDelta } from '$app/utils/document/blocks/common';
import { isSameDelta } from '$app/utils/document/blocks/text/delta';
import { debounce } from '$app/utils/tool';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useTextSelections } from '$app/components/document/_shared/Text/TextSelection.hooks';

export function useTextInput(id: string) {
  const { node } = useSubscribeNode(id);

  const [editor] = useState(() => withReact(createEditor()));
  const isComposition = useRef(false);
  const { setLastActiveSelection, ...selectionProps } = useTextSelections(id, editor);

  const delta = useMemo(() => {
    if (!node || !('delta' in node.data)) {
      return [];
    }
    return node.data.delta;
  }, [node]);
  const [value, setValue] = useState<Descendant[]>(deltaToSlateValue(delta));

  const { sync, receive } = useUpdateDelta(id, editor);

  // Update the editor's value when the node's delta changes.
  useEffect(() => {
    // If composition is in progress, do nothing.
    if (isComposition.current) return;
    receive(delta, setValue);
  }, [delta, receive]);

  // Update the node's delta when the editor's value changes.
  const onChange = useCallback(
    (e: Descendant[]) => {
      // Update the editor's value and selection.
      setValue(e);
      // If the selection is not null, update the last active selection.
      if (editor.selection !== null) setLastActiveSelection(editor.selection);
      // If composition is in progress, do nothing.
      if (isComposition.current) return;
      sync();
    },
    [editor.selection, setLastActiveSelection, sync]
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
    ...selectionProps,
    onDOMBeforeInput,
    onCompositionStart,
    onCompositionUpdate,
    onCompositionEnd,
  };
}

function useUpdateDelta(id: string, editor: Editor) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const penddingRef = useRef(false);

  const update = useCallback(() => {
    if (!controller) return;
    const delta = slateValueToDelta(editor.children);
    void (async () => {
      await dispatch(
        updateNodeDeltaThunk({
          id,
          delta,
          controller,
        })
      );
      // reset pendding flag
      penddingRef.current = false;
    })();
  }, [controller, dispatch, editor, id]);

  // when user input, update the node's delta after 200ms
  const debounceUpdate = useMemo(() => {
    return debounce(update, 50);
  }, [update]);

  const sync = useCallback(() => {
    // set pendding flag
    penddingRef.current = true;
    debounceUpdate();
  }, [debounceUpdate]);

  const receive = useCallback(
    (delta: TextDelta[], setValue: (children: Descendant[]) => void) => {
      // if pendding, do nothing
      if (penddingRef.current) return;

      // If the delta is the same as the editor's value, do nothing.
      const localDelta = slateValueToDelta(editor.children);
      const isSame = isSameDelta(delta, localDelta);
      if (isSame) return;

      Transforms.deselect(editor);
      const slateValue = deltaToSlateValue(delta);
      editor.children = slateValue;
      setValue(slateValue);
    },
    [editor]
  );

  useEffect(() => {
    return () => {
      debounceUpdate.cancel();
    };
  }, [debounceUpdate, update]);

  return {
    sync,
    receive,
  };
}
