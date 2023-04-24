import { triggerHotkey } from '@/appflowy_app/utils/slate/hotkey';
import { useCallback, useContext } from 'react';
import { Range, Editor, Element, Text, Location } from 'slate';
import { TextDelta } from '$app/interfaces/document';
import { useTextInput } from '../_shared/TextInput.hooks';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { DocumentControllerContext } from '@/appflowy_app/stores/effects/document/document_controller';
import {
  backspaceNodeThunk,
  indentNodeThunk,
  splitNodeThunk,
} from '@/appflowy_app/stores/reducers/document/async_actions';
import { documentActions, TextSelection } from '@/appflowy_app/stores/reducers/document/slice';

export function useTextBlock(id: string) {
  const { editor, onChange, value } = useTextInput(id);
  const { onTab, onBackSpace, onEnter } = useActions(id);
  const dispatch = useAppDispatch();

  const keepSelection = useCallback(() => {
    // This is a hack to make sure the selection is updated after next render
    // It will save the selection to the store, and the selection will be restored
    if (!editor.selection || !editor.selection.anchor || !editor.selection.focus) return;
    const { anchor, focus } = editor.selection;
    const selection = { anchor, focus } as TextSelection;
    dispatch(documentActions.setTextSelection({ blockId: id, selection }));
  }, [editor]);

  const onKeyDownCapture = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      switch (event.key) {
        // It should be handled when `Enter` is pressed
        case 'Enter': {
          if (!editor.selection) return;
          event.stopPropagation();
          event.preventDefault();
          // get the retain content
          const retainRange = getRetainRangeBy(editor);
          const retain = getDelta(editor, retainRange);
          // get the insert content
          const insertRange = getInsertRangeBy(editor);
          const insert = getDelta(editor, insertRange);
          void (async () => {
            // retain this node and insert a new node
            await onEnter(retain, insert);
          })();
          return;
        }
        // It should be handled when `Backspace` is pressed
        case 'Backspace': {
          if (!editor.selection) {
            return;
          }
          // It should be handled if the selection is collapsed and the cursor is at the beginning of the block
          const { anchor } = editor.selection;
          const isCollapsed = Range.isCollapsed(editor.selection);
          if (isCollapsed && anchor.offset === 0 && anchor.path.toString() === '0,0') {
            event.stopPropagation();
            event.preventDefault();
            keepSelection();
            void (async () => {
              await onBackSpace();
            })();
          }
          return;
        }
        // It should be handled when `Tab` is pressed
        case 'Tab': {
          event.stopPropagation();
          event.preventDefault();
          keepSelection();
          void (async () => {
            await onTab();
          })();

          return;
        }
      }
      triggerHotkey(event, editor);
    },
    [editor, keepSelection, onEnter, onBackSpace, onTab]
  );

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
