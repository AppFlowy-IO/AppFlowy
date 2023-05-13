import React, { useCallback, useContext, useMemo } from 'react';
import { BlockData, BlockType } from '$app/interfaces/document';

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
} from '@mui/icons-material';
import Popover, { PopoverProps } from '$app/components/document/_shared/Popover';
import { ListItemIcon, ListItemText, MenuItem } from '@mui/material';
import { useAppDispatch } from '$app/stores/store';
import { turnToBlockThunk } from '$app_reducers/document/async-actions';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
import { blockConfig } from '$app/constants/document/config';

const TurnIntoPopover = ({
  id,
  onClose,
  ...props
}: {
  id: string;
} & PopoverProps) => {
  const dispatch = useAppDispatch();
  const { node } = useSubscribeNode(id);
  const controller = useContext(DocumentControllerContext);

  const turnIntoBlock = useCallback(
    (type: BlockType, isSelected: boolean, data?: BlockData<any>) => {
      if (!controller || isSelected) {
        onClose?.();
        return;
      }

      const config = blockConfig[type];
      void (async () => {
        await dispatch(
          turnToBlockThunk({
            id,
            controller,
            type,
            data: {
              ...config.defaultData,
              delta: node?.data?.delta || [],
              ...data,
            },
          })
        );
        onClose?.();
      })();
    },
    [onClose, controller, dispatch, id, node]
  );

  const turnIntoHeading = useCallback(
    (level: number, isSelected: boolean) => {
      turnIntoBlock(BlockType.HeadingBlock, isSelected, { level });
    },
    [turnIntoBlock]
  );

  const options: {
    type: BlockType;
    title: string;
    icon: React.ReactNode;
    selected?: boolean;
    onClick?: (type: BlockType, isSelected: boolean) => void;
  }[] = useMemo(
    () => [
      {
        type: BlockType.TextBlock,
        title: 'Text',
        icon: <TextFields />,
      },
      {
        type: BlockType.HeadingBlock,
        title: 'Heading 1',
        icon: <Title />,
        selected: node?.data?.level === 1,
        onClick: (type: BlockType, isSelected: boolean) => {
          turnIntoHeading(1, isSelected);
        },
      },
      {
        type: BlockType.HeadingBlock,
        title: 'Heading 2',
        icon: <Title />,
        selected: node?.data?.level === 2,
        onClick: (type: BlockType, isSelected: boolean) => {
          turnIntoHeading(2, isSelected);
        },
      },
      {
        type: BlockType.HeadingBlock,
        title: 'Heading 3',
        icon: <Title />,
        selected: node?.data?.level === 3,
        onClick: (type: BlockType, isSelected: boolean) => {
          turnIntoHeading(3, isSelected);
        },
      },
      {
        type: BlockType.TodoListBlock,
        title: 'To-do list',
        icon: <Check />,
      },
      {
        type: BlockType.BulletedListBlock,
        title: 'Bulleted list',
        icon: <FormatListBulleted />,
      },
      {
        type: BlockType.NumberedListBlock,
        title: 'Numbered list',
        icon: <FormatListNumbered />,
      },
      {
        type: BlockType.ToggleListBlock,
        title: 'Toggle list',
        icon: <ArrowRight />,
      },
      {
        type: BlockType.CodeBlock,
        title: 'Code',
        icon: <DataObject />,
      },
      {
        type: BlockType.QuoteBlock,
        title: 'Quote',
        icon: <FormatQuote />,
      },
      {
        type: BlockType.CalloutBlock,
        title: 'Callout',
        icon: <Lightbulb />,
      },
    ],
    [node?.data?.level, turnIntoHeading]
  );

  return (
    <Popover onClose={onClose} {...props}>
      {options.map((option) => {
        const isSelected = option.type === node.type && option.selected !== false;
        return (
          <MenuItem
            className={'w-[100%]'}
            key={option.title}
            onClick={() =>
              option.onClick ? option.onClick(option.type, isSelected) : turnIntoBlock(option.type, isSelected)
            }
          >
            <ListItemIcon>{option.icon}</ListItemIcon>
            <ListItemText>{option.title}</ListItemText>
            <ListItemIcon>{isSelected ? <Check /> : null}</ListItemIcon>
          </MenuItem>
        );
      })}
    </Popover>
  );
};

export default TurnIntoPopover;
