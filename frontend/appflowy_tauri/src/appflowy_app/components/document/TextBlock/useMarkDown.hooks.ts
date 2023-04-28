import { useCallback, useContext, useMemo } from 'react';
import { TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { canHandleToHeadingBlock } from '$app/utils/document/slate/markdown';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { turnToHeadingBlockThunk } from '$app_reducers/document/async-actions/blocks/heading';

export function useMarkDown(id: string) {
  const { toHeadingBlockAction } = useActions(id);
  const toHeadingBlockEvent = useMemo(() => {
    return {
      triggerEventKey: keyBoardEventKeyMap.Space,
      canHandle: canHandleToHeadingBlock,
      handler: toHeadingBlockAction,
    };
  }, [toHeadingBlockAction]);

  const markdownEvents = useMemo(() => [toHeadingBlockEvent], [toHeadingBlockEvent]);

  return {
    markdownEvents,
  };
}

function useActions(id: string) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const toHeadingBlockAction = useCallback(
    (...args: TextBlockKeyEventHandlerParams) => {
      if (!controller) return;
      const [_event, editor] = args;
      dispatch(turnToHeadingBlockThunk({ id, editor, controller }));
    },
    [controller, dispatch, id]
  );

  return {
    toHeadingBlockAction,
  };
}
