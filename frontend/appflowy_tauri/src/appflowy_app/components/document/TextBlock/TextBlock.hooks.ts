import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';
import { useCallback, useContext, useState } from 'react';
import { Descendant, Range, Editor, Element, Text, Location } from 'slate';
import { TextDelta } from '$app/interfaces/document';
import { useTextInput } from '../_shared/TextInput.hooks';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { DocumentControllerContext } from '@/appflowy_app/stores/effects/document/document_controller';
import {
  backspaceNodeThunk,
  indentNodeThunk,
  splitNodeThunk,
} from '@/appflowy_app/stores/reducers/document/async_actions';
import { TextSelection } from '@/appflowy_app/stores/reducers/document/slice';

export function useTextBlock(id: string, delta: TextDelta[]) {
  const { editor, onSelectionChange } = useTextInput(id, delta);
  const [value, setValue] = useState<Descendant[]>([]);
  const { onTab, onBackSpace, onEnter } = useActions(id);
  const onChange = useCallback(
    (e: Descendant[]) => {
      setValue(e);
      editor.operations.forEach((op) => {
        if (op.type === 'set_selection') {
          onSelectionChange(op.newProperties as TextSelection);
        }
      });
    },
    [editor]
  );

  const onKeyDownCapture = (event: React.KeyboardEvent<HTMLDivElement>) => {
    switch (event.key) {
      case 'Enter': {
        if (!editor.selection) return;
        event.stopPropagation();
        event.preventDefault();
        const retainRange = getRetainRangeBy(editor);
        const retain = getDelta(editor, retainRange);
        const insertRange = getInsertRangeBy(editor);
        const insert = getDelta(editor, insertRange);
        void (async () => {
          await onEnter(retain, insert);
        })();
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

function useActions(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const onTab = useCallback(async () => {
    if (!controller) return;
    await dispatch(
      indentNodeThunk({
        id,
        controller,
      })
    );
  }, [id, controller]);

  const onBackSpace = useCallback(async () => {
    if (!controller) return;
    await dispatch(backspaceNodeThunk({ id, controller }));
  }, [controller, id]);

  const onEnter = useCallback(
    async (retain: TextDelta[], insert: TextDelta[]) => {
      if (!controller) return;
      await dispatch(splitNodeThunk({ id, retain, insert, controller }));
    },
    [controller, id]
  );

  return {
    onTab,
    onBackSpace,
    onEnter,
  };
}

function getDelta(editor: Editor, at: Location): TextDelta[] {
  const baseElement = Editor.fragment(editor, at)[0] as Element;
  return baseElement.children.map((item) => {
    const { text, ...attributes } = item as Text;
    return {
      insert: text,
      attributes,
    };
  });
}

function getRetainRangeBy(editor: Editor) {
  const start = Editor.start(editor, editor.selection!);
  return {
    anchor: { path: [0, 0], offset: 0 },
    focus: start,
  };
}

function getInsertRangeBy(editor: Editor) {
  const end = Editor.end(editor, editor.selection!);
  const fragment = (editor.children[0] as Element).children;
  return {
    anchor: end,
    focus: { path: [0, fragment.length - 1], offset: (fragment[fragment.length - 1] as Text).text.length },
  };
}
