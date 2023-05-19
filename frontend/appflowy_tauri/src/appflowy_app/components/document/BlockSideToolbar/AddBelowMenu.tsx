import React, { useCallback, useContext, useMemo } from 'react';
import MenuItem from '$app/components/document/BlockSideToolbar/MenuItem';
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
import { List } from '@mui/material';
import { BlockData, BlockType } from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { insertAfterNodeThunk } from '$app_reducers/document/async-actions';
import { blockConfig } from '$app/constants/document/config';
import { DocumentControllerContext } from '$app/stores/effects/document/document_controller';

function AddBelowMenu({ id, onClose }: { id: string; onClose: () => void }) {
  const dispatch = useAppDispatch();
  const controller = useContext(DocumentControllerContext);
  const handleInsert = useCallback(
    async (type: BlockType, data?: BlockData<any>) => {
      if (!controller) return;
      const defaultData = blockConfig[type].defaultData;
      await dispatch(
        insertAfterNodeThunk({
          id,
          controller,
          type,
          data: {
            ...defaultData,
            ...data,
          },
        })
      );
      onClose();
    },
    [controller, dispatch, id, onClose]
  );

  const optionColumns = useMemo(
    () => [
      [
        {
          type: BlockType.TextBlock,
          title: 'Text',
          icon: <TextFields />,
        },
        {
          type: BlockType.HeadingBlock,
          title: 'Heading 1',
          icon: <Title />,
          props: {
            level: 1,
          },
        },
        {
          type: BlockType.HeadingBlock,
          title: 'Heading 2',
          icon: <Title />,
          props: {
            level: 2,
          },
        },
        {
          type: BlockType.HeadingBlock,
          title: 'Heading 3',
          icon: <Title />,
          props: {
            level: 3,
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
      ],
      [
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
    ],
    []
  );
  return (
    <div
      onMouseDown={(e) => {
        e.preventDefault();
        e.stopPropagation();
      }}
      className={'flex'}
    >
      {optionColumns.map((column, index) => (
        <List key={index} className={'flex-1'}>
          {column.map((option) => {
            return (
              <MenuItem
                key={option.title}
                title={option.title}
                icon={option.icon}
                onClick={() => {
                  handleInsert(option.type, option.props);
                }}
              />
            );
          })}
        </List>
      ))}
    </div>
  );
}

export default AddBelowMenu;
