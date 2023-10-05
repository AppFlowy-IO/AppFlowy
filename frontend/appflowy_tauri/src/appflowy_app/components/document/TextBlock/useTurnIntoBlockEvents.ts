import { useCallback, useMemo } from 'react';
import { BlockType } from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { blockConfig } from '$app/constants/document/config';

import Delta, { Op } from 'quill-delta';
import { useRangeRef } from '$app/components/document/_shared/SubscribeSelection.hooks';
import { getBlock, getBlockDelta } from '$app/components/document/_shared/SubscribeNode.hooks';
import isHotkey from 'is-hotkey';
import { slashCommandActions } from '$app_reducers/document/slice';
import { getDeltaText } from '$app/utils/document/delta';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { turnIntoConfig } from './shortchut';

export function useTurnIntoBlockEvents(id: string) {
  const { docId, controller } = useSubscribeDocument();

  const dispatch = useAppDispatch();
  const rangeRef = useRangeRef();

  const getFlag = useCallback(() => {
    const range = rangeRef.current?.caret;

    if (!range || range.id !== id) return;

    const delta = getBlockDelta(docId, id);

    if (!delta) return '';
    return getDeltaText(delta.slice(0, range.index));
  }, [docId, id, rangeRef]);

  const getDeltaContent = useCallback(() => {
    const range = rangeRef.current?.caret;

    if (!range || range.id !== id) return;
    const delta = getBlockDelta(docId, id);

    if (!delta) return '';
    const content = delta.slice(range.index);

    return new Delta(content);
  }, [docId, id, rangeRef]);

  const canHandle = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>, type: BlockType) => {
      {
        const triggerKey = event.key === turnIntoConfig[type].triggerKey ? event.key : undefined;

        if (!triggerKey) return false;

        const regex = turnIntoConfig[type].markdownRegexp;

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

        return regex.test(`${flag}${triggerKey}`);
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

  const getAttrs = useCallback(
    (type: BlockType) => {
      const flag = getFlag();

      if (!flag) return;
      const triggerKey = turnIntoConfig[type].triggerKey;
      const regex = turnIntoConfig[type].markdownRegexp;
      const match = `${flag}${triggerKey}`.match(regex);

      return match?.[3];
    },
    [getFlag]
  );

  const spaceTriggerMap = useMemo(() => {
    return {
      [BlockType.HeadingBlock]: () => {
        const flag = getFlag();

        if (!flag) return;
        const level = flag.match(/#/g)?.length;

        if (!level || level > 3) return;
        return {
          level,
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

      return {
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => canHandle(e, blockType),
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
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => canHandle(e, BlockType.DividerBlock),
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          if (!controller) return;
          const delta = getDeltaContent();

          dispatch(
            turnToBlockThunk({
              id,
              controller,
              type: BlockType.DividerBlock,
              data: {},
            })
          );
        },
      },
      {
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => canHandle(e, BlockType.CodeBlock),
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          if (!controller) return;
          const defaultData = blockConfig[BlockType.CodeBlock].defaultData;

          dispatch(
            turnToBlockThunk({
              id,
              data: {
                ...defaultData,
              },
              type: BlockType.CodeBlock,
              controller,
            })
          );
        },
      },
      {
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => canHandle(e, BlockType.EquationBlock),
        handler: (e: React.KeyboardEvent<HTMLDivElement>) => {
          e.preventDefault();
          const formula = getAttrs(BlockType.EquationBlock);

          const data = {
            formula,
          };

          dispatch(turnToBlockThunk({ id, data, type: BlockType.EquationBlock, controller }));
        },
      },
      {
        // Here custom slash key event for TextBlock
        canHandle: (e: React.KeyboardEvent<HTMLDivElement>) => {
          const flag = getFlag();

          return isHotkey('/', e) && flag === '';
        },
        handler: (_: React.KeyboardEvent<HTMLDivElement>) => {
          if (!controller) return;
          dispatch(
            slashCommandActions.openSlashCommand({
              blockId: id,
              docId,
            })
          );
        },
      },
    ];
  }, [canHandle, controller, dispatch, docId, getAttrs, getDeltaContent, getFlag, id, spaceTriggerMap]);

  return turnIntoBlockEvents;
}
