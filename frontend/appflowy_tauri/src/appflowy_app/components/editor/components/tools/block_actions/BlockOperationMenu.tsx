import React, { useMemo } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { useTranslation } from 'react-i18next';
import { Button } from '@mui/material';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { Element } from 'slate';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

export function BlockOperationMenu({
  node,
  ...props
}: {
  node: Element;
} & PopoverProps) {
  const editor = useSlateStatic();
  const { t } = useTranslation();
  const options = useMemo(
    () => [
      {
        icon: <DeleteSvg />,
        text: t('button.delete'),
        onClick: () => {
          CustomEditor.deleteNode(editor, node);
          props.onClose?.({}, 'backdropClick');
        },
      },
      {
        icon: <CopySvg />,
        text: t('button.duplicate'),
        onClick: () => {
          CustomEditor.duplicateNode(editor, node);
          props.onClose?.({}, 'backdropClick');
        },
      },
    ],
    [editor, node, props, t]
  );

  return (
    <Popover {...PopoverCommonProps} {...props}>
      <div className={'flex flex-col p-2'}>
        {options.map((option, index) => (
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
    </Popover>
  );
}

export default BlockOperationMenu;
