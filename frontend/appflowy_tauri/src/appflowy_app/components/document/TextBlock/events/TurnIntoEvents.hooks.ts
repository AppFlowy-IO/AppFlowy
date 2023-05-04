import { useContext, useMemo } from 'react';
import { BlockData, BlockType, TextBlockKeyEventHandlerParams } from '$app/interfaces/document';
import { keyBoardEventKeyMap } from '$app/constants/document/text_block';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { turnToBlockThunk, turnToDividerBlockThunk } from '$app_reducers/document/async-actions';
import { blockConfig } from '$app/constants/document/config';
import { Editor } from 'slate';
import { getBeforeRangeAt } from '$app/utils/document/blocks/text/delta';
import {
  getHeadingDataFromEditor,
  getQuoteDataFromEditor,
  getTodoListDataFromEditor,
  getBulletedDataFromEditor,
  getNumberedListDataFromEditor,
  getToggleListDataFromEditor,
  getCalloutDataFromEditor,
} from '$app/utils/document/blocks';
import { getDeltaAfterSelection } from '$app/utils/document/blocks/common';

export function useTurnIntoBlock(id: string) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();

  const turnIntoBlockEvents = useMemo(() => {
    const spaceTriggerEvents = Object.entries({
      [BlockType.HeadingBlock]: getHeadingDataFromEditor,
      [BlockType.TodoListBlock]: getTodoListDataFromEditor,
      [BlockType.QuoteBlock]: getQuoteDataFromEditor,
      [BlockType.BulletedListBlock]: getBulletedDataFromEditor,
      [BlockType.NumberedListBlock]: getNumberedListDataFromEditor,
      [BlockType.ToggleListBlock]: getToggleListDataFromEditor,
      [BlockType.CalloutBlock]: getCalloutDataFromEditor,
    }).map(([type, getData]) => {
      const blockType = type as BlockType;
      const triggerKey = keyBoardEventKeyMap.Space;
      return {
        triggerEventKey: keyBoardEventKeyMap.Space,
        canHandle: canHandle(blockType, triggerKey),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          if (!controller) return;
          const [_event, editor] = args;
          const data = getData(editor);
          if (!data) return;
          dispatch(turnToBlockThunk({ id, data, type: blockType, controller }));
        },
      };
    });
    return [
      ...spaceTriggerEvents,
      {
        triggerEventKey: keyBoardEventKeyMap.Reduce,
        canHandle: canHandle(BlockType.DividerBlock, keyBoardEventKeyMap.Reduce),
        handler: (...args: TextBlockKeyEventHandlerParams) => {
          if (!controller) return;
          const [_event, editor] = args;
          const delta = getDeltaAfterSelection(editor) || [];
          dispatch(turnToDividerBlockThunk({ id, controller, delta }));
        },
      },
    ];
  }, [controller, dispatch, id]);

  return {
    turnIntoBlockEvents,
  };
}

function canHandle(type: BlockType, triggerKey: string) {
  const config = blockConfig[type];

  const regex = config.markdownRegexps;
  // This error will be thrown if the block type is not in the config, and it will happen in development environment
  if (!regex) {
    throw new Error(`canHandle: block type ${type} is not supported`);
  }

  return (...args: TextBlockKeyEventHandlerParams) => {
    const [event, editor] = args;
    const isTrigger = event.key === triggerKey;
    const selection = editor.selection;

    if (!isTrigger || !selection) {
      return false;
    }

    const flag = Editor.string(editor, getBeforeRangeAt(editor, selection)).trim();
    if (flag === null) return false;

    return regex.some((r) => r.test(`${flag}${triggerKey}`));
  };
}
