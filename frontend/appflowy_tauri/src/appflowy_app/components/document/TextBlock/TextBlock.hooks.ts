import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';
import { useCallback, useContext, useState } from 'react';
import { Descendant, Range } from 'slate';
import { NestedBlock, TextDelta } from '$app/interfaces/document';
import { useTextInput } from '../_shared/TextInput.hooks';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { DocumentControllerContext } from '@/appflowy_app/stores/effects/document/document_controller';
import { backspaceNodeThunk, indentNodeThunk } from '@/appflowy_app/stores/reducers/document/async_actions';

export function useTextBlock(node: NestedBlock, delta: TextDelta[]) {
  const { editor } = useTextInput(delta);
  const [value, setValue] = useState<Descendant[]>([]);
  const { onTab, onBackSpace } = useActions(node);
  const onChange = useCallback(
    (e: Descendant[]) => {
      setValue(e);
    },
    [editor]
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
        const isCollapsed = Range.isCollapsed(editor.selection);
        if (isCollapsed && anchor.offset === 0 && anchor.path.toString() === '0,0') {
          event.stopPropagation();
          event.preventDefault();
          void (async () => {
            await onBackSpace();
          })();
        }
        return;
      }
      case 'Tab': {
        event.stopPropagation();
        event.preventDefault();
        void (async () => {
          await onTab();
        })();

        return;
      }
    }
    triggerHotkey(event, editor);
  };

  const onDOMBeforeInput = useCallback((e: InputEvent) => {
    // COMPAT: in Apple, `compositionend` is dispatched after the `beforeinput` for "insertFromComposition".
    // It will cause repeated characters when inputting Chinese.
    // Here, prevent the beforeInput event and wait for the compositionend event to take effect.
    if (e.inputType === 'insertFromComposition') {
      e.preventDefault();
    }
  }, []);

  return {
    onChange,
    onKeyDownCapture,
    onDOMBeforeInput,
    editor,
    value,
  };
}

function useActions(node: NestedBlock) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const onTab = useCallback(async () => {
    if (!node || !controller) return;
    await dispatch(
      indentNodeThunk({
        id: node.id,
        controller,
      })
    );
  }, [node, controller]);

  const onBackSpace = useCallback(async () => {
    if (!controller || !node) return;
    await dispatch(backspaceNodeThunk({ id: node.id, controller }));
  }, [controller, node]);

  return {
    onTab,
    onBackSpace,
  };
}
