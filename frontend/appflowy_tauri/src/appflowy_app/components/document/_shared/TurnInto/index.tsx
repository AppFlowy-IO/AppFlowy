import React, { useCallback, useEffect, useMemo } from 'react';
import { BlockType, SlashCommandOptionKey } from '$app/interfaces/document';

import {
  ArrowRight,
  Check,
  DataObject,
  FormatListBulleted,
  FormatListNumbered,
  FormatQuote,
  Lightbulb,
  TextFields,
  Title,
  Functions,
} from '@mui/icons-material';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useTurnInto } from '$app/components/document/_shared/TurnInto/TurnInto.hooks';
import { Keyboard } from '$app/constants/document/keyboard';
import MenuItem from '$app/components/document/_shared/MenuItem';
import { selectOptionByUpDown } from '$app/utils/document/menu';

interface Option {
  key: SlashCommandOptionKey;
  type: BlockType;
  title: string;
  icon: React.ReactNode;
  selected?: boolean;
  onClick?: (type: BlockType, isSelected: boolean) => void;
}
const TurnIntoPopover = ({
  id,
  onClose,
  onOk,
  ...props
}: {
  id: string;
  onClose?: () => void;
  onOk?: () => void;
} & PopoverProps) => {
  const { node } = useSubscribeNode(id);
  const { turnIntoHeading, turnIntoBlock } = useTurnInto({ node, onClose });
  const [hovered, setHovered] = React.useState<SlashCommandOptionKey>();

  const options: Option[] = useMemo(
    () => [
      {
        key: SlashCommandOptionKey.TEXT,
        type: BlockType.TextBlock,
        title: 'Text',
        icon: <TextFields />,
      },
      {
        key: SlashCommandOptionKey.HEADING_1,
        type: BlockType.HeadingBlock,
        title: 'Heading 1',
        icon: <Title />,
        selected: node?.data?.level === 1,
        onClick: (type: BlockType, isSelected: boolean) => {
          turnIntoHeading(1, isSelected);
        },
      },
      {
        key: SlashCommandOptionKey.HEADING_2,
        type: BlockType.HeadingBlock,
        title: 'Heading 2',
        icon: <Title />,
        selected: node?.data?.level === 2,
        onClick: (type: BlockType, isSelected: boolean) => {
          turnIntoHeading(2, isSelected);
        },
      },
      {
        key: SlashCommandOptionKey.HEADING_3,
        type: BlockType.HeadingBlock,
        title: 'Heading 3',
        icon: <Title />,
        selected: node?.data?.level === 3,
        onClick: (type: BlockType, isSelected: boolean) => {
          turnIntoHeading(3, isSelected);
        },
      },
      {
        key: SlashCommandOptionKey.TODO,
        type: BlockType.TodoListBlock,
        title: 'To-do list',
        icon: <Check />,
      },
      {
        key: SlashCommandOptionKey.BULLET,
        type: BlockType.BulletedListBlock,
        title: 'Bulleted list',
        icon: <FormatListBulleted />,
      },
      {
        key: SlashCommandOptionKey.NUMBER,
        type: BlockType.NumberedListBlock,
        title: 'Numbered list',
        icon: <FormatListNumbered />,
      },
      {
        key: SlashCommandOptionKey.TOGGLE,
        type: BlockType.ToggleListBlock,
        title: 'Toggle list',
        icon: <ArrowRight />,
      },
      {
        key: SlashCommandOptionKey.CODE,
        type: BlockType.CodeBlock,
        title: 'Code',
        icon: <DataObject />,
      },
      {
        key: SlashCommandOptionKey.QUOTE,
        type: BlockType.QuoteBlock,
        title: 'Quote',
        icon: <FormatQuote />,
      },
      {
        key: SlashCommandOptionKey.CALLOUT,
        type: BlockType.CalloutBlock,
        title: 'Callout',
        icon: <Lightbulb />,
      },
      {
        key: SlashCommandOptionKey.EQUATION,
        type: BlockType.EquationBlock,
        title: 'Block Equation',
        icon: <Functions />,
      },
    ],
    [node?.data?.level, turnIntoHeading]
  );

  const getSelected = useCallback(
    (option: Option) => {
      return option.type === node.type && option.selected !== false;
    },
    [node?.type]
  );

  const onClick = useCallback(
    (option: Option) => {
      const isSelected = getSelected(option);

      option.onClick ? option.onClick(option.type, isSelected) : turnIntoBlock(option.type, isSelected);
      onOk?.();
    },
    [onOk, getSelected, turnIntoBlock]
  );

  const onKeyDown = useCallback(
    (e: KeyboardEvent) => {
      e.stopPropagation();
      e.preventDefault();
      const isUp = e.key === Keyboard.keys.UP;
      const isDown = e.key === Keyboard.keys.DOWN;
      const isEnter = e.key === Keyboard.keys.ENTER;
      const isLeft = e.key === Keyboard.keys.LEFT;

      if (isLeft) {
        onClose?.();
        return;
      }

      if (!isUp && !isDown && !isEnter) return;
      if (isEnter) {
        const option = options.find((option) => option.key === hovered);

        if (option) {
          onClick(option);
        }

        return;
      }

      const nextKey = selectOptionByUpDown(
        isUp,
        String(hovered),
        options.map((option) => String(option.key))
      );
      const nextOption = options.find((option) => String(option.key) === nextKey);

      setHovered(nextOption?.key);
    },
    [hovered, onClick, onClose, options]
  );

  useEffect(() => {
    if (props.open) {
      document.addEventListener('keydown', onKeyDown, true);
    }

    return () => {
      document.removeEventListener('keydown', onKeyDown, true);
    };
  }, [onKeyDown, props.open]);

  return (
    <Popover disableAutoFocus={true} onClose={onClose} {...props}>
      <div className={'min-w-[220px] p-2'}>
        {options.map((option) => {
          return (
            <MenuItem
              iconSize={{
                width: 20,
                height: 20,
              }}
              icon={option.icon}
              title={option.title}
              isHovered={hovered === option.key}
              extra={getSelected(option) ? <Check /> : null}
              className={'w-[100%]'}
              key={option.title}
              onClick={() => onClick(option)}
            ></MenuItem>
          );
        })}
      </div>
    </Popover>
  );
};

export default TurnIntoPopover;
