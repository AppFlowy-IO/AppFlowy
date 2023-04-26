import { useCallback, useContext, useMemo } from 'react';
import { Editor } from 'slate';
import { TextDelta, TextSelection } from '$app/interfaces/document';
import { useTextInput } from '../_shared/TextInput.hooks';
import { useAppDispatch } from '@/appflowy_app/stores/store';
import { DocumentControllerContext } from '@/appflowy_app/stores/effects/document/document_controller';
import {
  backspaceNodeThunk,
  indentNodeThunk,
  splitNodeThunk,
} from '@/appflowy_app/stores/reducers/document/async_actions';
import { documentActions } from '@/appflowy_app/stores/reducers/document/slice';
import {
  triggerHotkey,
  canHandleEnterKey,
  canHandleBackspaceKey,
  canHandleTabKey,
  onHandleEnterKey,
} from '@/appflowy_app/utils/slate/hotkey';

export function useTextBlock(id: string) {
  const { editor, onChange, value } = useTextInput(id);
  const { onKeyDown } = useTextBlockKeyEvent(id, editor);

  const onKeyDownCapture = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      onKeyDown(event);
    },
    [onKeyDown]
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

// eslint-disable-next-line no-shadow
enum TextBlockKeyEvent {
  Enter,
  BackSpace,
  Tab,
}

type TextBlockKeyEventHandlerParams = [React.KeyboardEvent<HTMLDivElement>, Editor];

function useTextBlockKeyEvent(id: string, editor: Editor) {
  const { tabAction, backSpaceAction, enterAction } = useActions(id);

  const dispatch = useAppDispatch();
  const keepSelection = useCallback(() => {
    // This is a hack to make sure the selection is updated after next render
    // It will save the selection to the store, and the selection will be restored
    if (!editor.selection || !editor.selection.anchor || !editor.selection.focus) return;
    const { anchor, focus } = editor.selection;
    const selection = { anchor, focus } as TextSelection;
    dispatch(documentActions.setTextSelection({ blockId: id, selection }));
  }, [editor]);

  // This is list of key events that can be handled by TextBlock
  const keyEvents = useMemo(() => {
    return [
      {
        key: TextBlockKeyEvent.Enter,
        canHandle: canHandleEnterKey,
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          onHandleEnterKey(...args, enterAction);
        },
      },
      {
        key: TextBlockKeyEvent.BackSpace,
        canHandle: canHandleBackspaceKey,
        handler: (..._args: TextBlockKeyEventHandlerParams) => {
          keepSelection();
          void backSpaceAction();
        },
      },
      {
        key: TextBlockKeyEvent.Tab,
        canHandle: canHandleTabKey,
        handler: (..._args: TextBlockKeyEventHandlerParams) => {
          keepSelection();
          void tabAction();
        },
      },
    ];
  }, [keepSelection, enterAction, tabAction, backSpaceAction]);

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      const matchKey = keyEvents.find((keyEvent) => keyEvent.canHandle(event, editor));
      if (!matchKey) {
        triggerHotkey(event, editor);
        return;
      }

      event.stopPropagation();
      event.preventDefault();
      matchKey.handler(event, editor);
    },
    [keyEvents, editor]
  );

  return {
    onKeyDown,
  };
}
function useActions(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const tabAction = useCallback(async () => {
    if (!controller) return;
    await dispatch(
      indentNodeThunk({
        id,
        controller,
      })
    );
  }, [id, controller]);

  const backSpaceAction = useCallback(async () => {
    if (!controller) return;
    await dispatch(backspaceNodeThunk({ id, controller }));
  }, [controller, id]);

  const enterAction = useCallback(
    async (retain: TextDelta[], insert: TextDelta[]) => {
      if (!controller) return;
      await dispatch(splitNodeThunk({ id, retain, insert, controller }));
    },
    [controller, id]
  );

  return {
    tabAction,
    backSpaceAction,
    enterAction,
  };
}
