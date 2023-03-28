import { triggerHotkey } from "@/appflowy_app/utils/slate/hotkey";
import { useCallback, useContext, useMemo, useRef, useState } from "react";
import { Descendant, Range } from "slate";
import { useBindYjs } from "./BindYjs.hooks";
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { TextDelta } from '$app/interfaces/document';
import { debounce } from "@/appflowy_app/utils/tool";

function useController(textId: string) {
  const docController = useContext(DocumentControllerContext);

  const update  = useCallback(
    (delta: TextDelta[]) => {
      docController?.yTextApply(textId, delta)
    },
    [textId],
  );
  const transact = useCallback(
    (actions: (() => void)[]) => {
      docController?.transact(actions)
    },
    [textId],
  )
  
  return {
    update,
    transact
  }
}

function useTransact(textId: string) {
  const pendingActions = useRef<(() => void)[]>([]);
  const { update, transact } = useController(textId);

  const sendTransact = useCallback(
    () => {
      const actions = pendingActions.current;
      transact(actions);
    },
    [transact],
  )
  
  const debounceSendTransact = useMemo(() => debounce(sendTransact, 300), [transact]);

  const sendDelta = useCallback(
    (delta: TextDelta[]) => {
      const action = () => update(delta);
      pendingActions.current.push(action);
      debounceSendTransact()
    },
    [update, debounceSendTransact],
  );
  return {
    sendDelta
  }
}

export function useTextBlock(text: string, delta: TextDelta[]) {
  const { sendDelta } = useTransact(text);

  const { editor } = useBindYjs(delta, sendDelta);
  const [value, setValue] = useState<Descendant[]>([]);
  
  const onChange = useCallback(
    (e: Descendant[]) => {
      setValue(e);
    },
    [editor],
  );

  const onKeyDownCapture = (event: React.KeyboardEvent<HTMLDivElement>) => {
    switch (event.key) {
      case 'Enter': {
        event.stopPropagation();
        event.preventDefault();

        return;
      }
      case 'Backspace': {
        if (!editor.selection) return;
        const { anchor } = editor.selection;
        const isCollapase = Range.isCollapsed(editor.selection);
        if (isCollapase && anchor.offset === 0 && anchor.path.toString() === '0,0') {
          event.stopPropagation();
          event.preventDefault();
          return;
        }
      }
    }
    triggerHotkey(event, editor);
  }

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the
    // `beforeinput` for "insertFromComposition". It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }

  }, []);

  return {
    onChange,
    onKeyDownCapture,
    onDOMBeforeInput,
    editor,
    value
  }
}
