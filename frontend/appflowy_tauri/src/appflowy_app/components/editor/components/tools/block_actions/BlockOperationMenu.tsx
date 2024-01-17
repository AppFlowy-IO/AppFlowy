import React, { useCallback, useMemo } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { useTranslation } from 'react-i18next';
import { Button, Divider } from '@mui/material';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { Element } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { useBlockMenuKeyDown } from '$app/components/editor/components/tools/block_actions/BlockMenu.hooks';
import { Color } from './color';

export function BlockOperationMenu({
  node,
  ...props
}: {
  node: Element;
} & PopoverProps) {
  const editor = useSlateStatic();
  const { t } = useTranslation();

  const handleClose = useCallback(() => {
    props.onClose?.({}, 'backdropClick');
    ReactEditor.focus(editor);
    const path = ReactEditor.findPath(editor, node);

    editor.select(path);
    if (editor.isSelectable(node)) {
      editor.collapse({
        edge: 'start',
      });
    }
  }, [editor, node, props]);

  const { onKeyDown } = useBlockMenuKeyDown({
    onClose: handleClose,
  });

  const operationOptions = useMemo(
    () => [
      {
        icon: <DeleteSvg />,
        text: t('button.delete'),
        onClick: () => {
          CustomEditor.deleteNode(editor, node);
          handleClose();
        },
      },
      {
        icon: <CopySvg />,
        text: t('button.duplicate'),
        onClick: () => {
          CustomEditor.duplicateNode(editor, node);
          handleClose();
        },
      },
    ],
    [editor, node, handleClose, t]
  );

  return (
    <Popover
      {...PopoverCommonProps}
      disableAutoFocus={false}
      onKeyDown={onKeyDown}
      onMouseDown={(e) => e.stopPropagation()}
      {...props}
      onClose={handleClose}
    >
      <div className={'flex flex-col p-2'}>
        {operationOptions.map((option, index) => (
          <Button
            color={'inherit'}
            onClick={option.onClick}
            startIcon={option.icon}
            size={'small'}
            className={'w-full justify-start'}
            key={index}
          >
            {option.text}
          </Button>
        ))}
      </div>
      <Divider className={'my-1'} />
      <Color
        node={
          node as Element & {
            data?: {
              font_color?: string;
              bg_color?: string;
            };
          }
        }
        onClose={handleClose}
      />
    </Popover>
  );
}

export default BlockOperationMenu;
