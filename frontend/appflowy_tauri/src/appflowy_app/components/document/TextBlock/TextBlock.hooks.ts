import { triggerHotkey } from "@/appflowy_app/utils/slate/hotkey";
import { useCallback, useContext, useState } from "react";
import { Descendant, Range } from "slate";
import { useBindYjs } from "./BindYjs.hooks";
import { YDocControllerContext } from '../../../stores/effects/document/document_controller';
import { Delta } from "@slate-yjs/core/dist/model/types";
import { TextDelta } from '../../../interfaces/document';

function useController(textId: string) {
  const docController = useContext(YDocControllerContext);
  
  const update  = useCallback(
    (delta: Delta) => {
      docController?.yTextApply(textId, delta)
    },
    [textId],
  )
  
  return {
    update
  }
}

export function useTextBlock(text: string, delta: TextDelta[]) {
  const { update } = useController(text);
  const { editor } = useBindYjs(delta, update);
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
