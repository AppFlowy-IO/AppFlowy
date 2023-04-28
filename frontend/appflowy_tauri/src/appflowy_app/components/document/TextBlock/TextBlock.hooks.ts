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
  keyBoardEventKeyMap,
  canHandleUpKey,
  canHandleDownKey,
  canHandleLeftKey,
  canHandleRightKey,
} from '@/appflowy_app/utils/slate/hotkey';
import { updateNodeDeltaThunk } from '$app/stores/reducers/document/async_actions/update';
import { setCursorPreLineThunk, setCursorNextLineThunk } from '$app/stores/reducers/document/async_actions/set_cursor';

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

type TextBlockKeyEventHandlerParams = [React.KeyboardEvent<HTMLDivElement>, Editor];

function useTextBlockKeyEvent(id: string, editor: Editor) {
  const { indentAction, backSpaceAction, splitAction, wrapAction, focusPreLineAction, focusNextLineAction } =
    useActions(id);

  const dispatch = useAppDispatch();
  const keepSelection = useCallback(() => {
    // This is a hack to make sure the selection is updated after next render
    // It will save the selection to the store, and the selection will be restored
    if (!editor.selection || !editor.selection.anchor || !editor.selection.focus) return;
    const { anchor, focus } = editor.selection;
    const selection = { anchor, focus } as TextSelection;
    dispatch(documentActions.setTextSelection({ blockId: id, selection }));
  }, [editor]);

  const enterEvent = useMemo(() => {
    return {
      key: keyBoardEventKeyMap.Enter,
      canHandle: canHandleEnterKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        onHandleEnterKey(...args, {
          onSplit: splitAction,
          onWrap: wrapAction,
        });
      },
    };
  }, [splitAction, wrapAction]);

  const tabEvent = useMemo(() => {
    return {
      key: keyBoardEventKeyMap.Tab,
      canHandle: canHandleTabKey,
      handler: (..._args: TextBlockKeyEventHandlerParams) => {
        keepSelection();
        void indentAction();
      },
    };
  }, [keepSelection, indentAction]);

  const backSpaceEvent = useMemo(() => {
    return {
      key: keyBoardEventKeyMap.Backspace,
      canHandle: canHandleBackspaceKey,
      handler: (..._args: TextBlockKeyEventHandlerParams) => {
        keepSelection();
        void backSpaceAction();
      },
    };
  }, [keepSelection, backSpaceAction]);

  const upEvent = useMemo(() => {
    return {
      key: keyBoardEventKeyMap.Up,
      canHandle: canHandleUpKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusPreLineAction({
          editor: args[1],
        });
      },
    };
  }, [focusPreLineAction]);

  const downEvent = useMemo(() => {
    return {
      key: keyBoardEventKeyMap.Down,
      canHandle: canHandleDownKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusNextLineAction({
          editor: args[1],
        });
      },
    };
  }, [focusNextLineAction]);

  const leftEvent = useMemo(() => {
    return {
      key: keyBoardEventKeyMap.Left,
      canHandle: canHandleLeftKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusPreLineAction({
          editor: args[1],
          focusEnd: true,
        });
      },
    };
  }, [focusPreLineAction]);

  const rightEvent = useMemo(() => {
    return {
      key: keyBoardEventKeyMap.Right,
      canHandle: canHandleRightKey,
      handler: (...args: TextBlockKeyEventHandlerParams) => {
        void focusNextLineAction({
          editor: args[1],
          focusStart: true,
        });
      },
    };
  }, [focusNextLineAction]);

  const onKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      // This is list of key events that can be handled by TextBlock
      const keyEvents = [enterEvent, backSpaceEvent, tabEvent, upEvent, downEvent, leftEvent, rightEvent];
      const matchKey = keyEvents.find((keyEvent) => keyEvent.canHandle(event, editor));
      if (!matchKey) {
        triggerHotkey(event, editor);
        return;
      }

      event.stopPropagation();
      event.preventDefault();
      matchKey.handler(event, editor);
    },
    [editor, enterEvent, backSpaceEvent, tabEvent, upEvent, downEvent, leftEvent, rightEvent]
  );

  return {
    onKeyDown,
  };
}

function useActions(id: string) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);

  const indentAction = useCallback(async () => {
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

  const splitAction = useCallback(
    async (retain: TextDelta[], insert: TextDelta[]) => {
      if (!controller) return;
      await dispatch(splitNodeThunk({ id, retain, insert, controller }));
    },
    [controller, id]
  );

  const wrapAction = useCallback(
    async (delta: TextDelta[], selection: TextSelection) => {
      if (!controller) return;
      await dispatch(updateNodeDeltaThunk({ id, delta, controller }));
      // This is a hack to make sure the selection is updated after next render
      dispatch(documentActions.setTextSelection({ blockId: id, selection }));
    },
    [controller, id]
  );

  const focusPreLineAction = useCallback(
    async (params: { editor: Editor; focusEnd?: boolean }) => {
      await dispatch(setCursorPreLineThunk({ id, ...params }));
    },
    [id]
  );

  const focusNextLineAction = useCallback(
    async (params: { editor: Editor; focusStart?: boolean }) => {
      await dispatch(setCursorNextLineThunk({ id, ...params }));
    },
    [id]
  );

  return {
    indentAction,
    backSpaceAction,
    splitAction,
    wrapAction,
    focusPreLineAction,
    focusNextLineAction,
  };
}
