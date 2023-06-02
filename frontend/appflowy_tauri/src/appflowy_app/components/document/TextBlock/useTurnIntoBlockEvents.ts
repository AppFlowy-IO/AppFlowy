import { useCallback, useContext, useMemo } from 'react';
import { BlockType } from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { blockConfig } from '$app/constants/document/config';

import Delta, { Op } from 'quill-delta';
import { useRangeRef } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { getBlock } from '$app/components/document/_shared/SubscribeNode.hooks';
import isHotkey from 'is-hotkey';
import { slashCommandActions } from '$app_reducers/document/slice';
import { Keyboard } from '$app/constants/document/keyboard';
import { getDeltaText } from '$app/utils/document/delta';

export function useTurnIntoBlockEvents(id: string) {
  const controller = useContext(DocumentControllerContext);
  const dispatch = useAppDispatch();
  const rangeRef = useRangeRef();

  const getFlag = useCallback(() => {
    const range = rangeRef.current?.caret;
    if (!range || range.id !== id) return;
    const node = getBlock(id);
    const delta = new Delta(node.data.delta || []);
    const flag = getDeltaText(delta.slice(0, range.index));
    return flag;
  }, [id, rangeRef]);

  const getDeltaContent = useCallback(() => {
    const range = rangeRef.current?.caret;
    if (!range || range.id !== id) return;
    const node = getBlock(id);
    const delta = new Delta(node.data.delta || []);
    const content = delta.slice(range.index);
    return new Delta(content);
  }, [id, rangeRef]);

  const canHandle = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>, type: BlockType, triggerKey: string) => {
      {
        const config = blockConfig[type];

        const regex = config.markdownRegexps;
        // This error will be thrown if the block type is not in the config, and it will happen in development environment
        if (!regex) {
          throw new Error(`canHandle: block type ${type} is not supported`);
        }

        const isTrigger = event.key === triggerKey;

        if (!isTrigger) {
          return false;
        }
        const flag = getFlag();
        if (!flag) return false;

        return regex.some((r) => r.test(`${flag}${triggerKey}`));
      }
    },
    [getFlag]
  );

  const getTurnIntoBlockDelta = useCallback(() => {
    const content = getDeltaContent();
    if (!content) return;
    return {
      delta: content.ops,
    };
  }, [getDeltaContent]);

  const spaceTriggerMap = useMemo(() => {
    return {
      [BlockType.HeadingBlock]: () => {
        const flag = getFlag();
        if (!flag) return;
        return {
          level: flag.match(/#/g)?.length,
          ...getTurnIntoBlockDelta(),
        };
      },
      [BlockType.TodoListBlock]: () => {
        const flag = getFlag();
        if (!flag) return;

        return {
          checked: flag.includes('[x]'),
          ...getTurnIntoBlockDelta(),
        };
      },
      [BlockType.QuoteBlock]: getTurnIntoBlockDelta,
      [BlockType.BulletedListBlock]: getTurnIntoBlockDelta,
      [BlockType.NumberedListBlock]: getTurnIntoBlockDelta,
      [BlockType.ToggleListBlock]: getTurnIntoBlockDelta,
      [BlockType.CalloutBlock]: () => {
        const flag = getFlag();
        if (!flag) return;
        const tag = flag.match(/(TIP|INFO|WARNING|DANGER)/g)?.[0];
        if (!tag) return;
        const iconMap: Record<string, string> = {
          TIP: '💡',
          INFO: '❗',
          WARNING: '⚠️',
          DANGER: '‼️',
        };
        return {
          icon: iconMap[tag],
          ...getTurnIntoBlockDelta(),
        };
      },
    };
  }, [getFlag, getTurnIntoBlockDelta]);

  const turnIntoBlockEvents = useMemo(() => {
    const spaceTriggerEvents = Object.entries(spaceTriggerMap).map(([type, getData]) => {
      const blockType = type as BlockType;
      const triggerKey = Keyboard.keys.Space;

      return {
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => canHandle(e, blockType, triggerKey),
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          if (!controller) return;
          const data = getData();
          if (!data) return;
          dispatch(turnToBlockThunk({ id, data, type: blockType, controller }));
        },
      };
    });
    return [
      ...spaceTriggerEvents,
      {
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) =>
          canHandle(e, BlockType.DividerBlock, Keyboard.keys.Reduce),
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          if (!controller) return;
          const delta = getDeltaContent();

          dispatch(
            turnToBlockThunk({
              id,
              controller,
              type: BlockType.DividerBlock,
              data: {
                delta: delta?.ops as Op[],
              },
            })
          );
        },
      },
      {
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) =>
          canHandle(e, BlockType.CodeBlock, Keyboard.keys.BackQuote),
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          if (!controller) return;
          const defaultData = blockConfig[BlockType.CodeBlock].defaultData;
          const data = {
            ...defaultData,
            delta: getDeltaContent()?.ops as Op[],
          };
          dispatch(turnToBlockThunk({ id, data, type: BlockType.CodeBlock, controller }));
        },
      },
      {
        // Here custom slash key event for TextBlock
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          const flag = getFlag();
          return isHotkey('/', e) && flag === '';
        },
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          if (!controller) return;
          dispatch(
            slashCommandActions.openSlashCommand({
              blockId: id,
            })
          );
        },
      },
    ];
  }, [canHandle, controller, dispatch, getDeltaContent, getFlag, id, spaceTriggerMap]);

  return turnIntoBlockEvents;
}
