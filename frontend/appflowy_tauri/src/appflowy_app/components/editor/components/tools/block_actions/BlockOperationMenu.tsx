import React, { useCallback, useMemo, useState } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';

import { useTranslation } from 'react-i18next';
import { Button, Divider, MenuProps, Menu } from '@mui/material';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { Element } from 'slate';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';

import { FontColorPicker, BgColorPicker } from '$app/components/editor/components/tools/_shared';
import Typography from '@mui/material/Typography';
import { useBlockMenuKeyDown } from '$app/components/editor/components/tools/block_actions/BlockMenu.hooks';

enum SubMenuType {
  TextColor = 'textColor',
  BackgroundColor = 'backgroundColor',
}

const subMenuProps: Partial<MenuProps> = {
  anchorOrigin: {
    vertical: 'top',
    horizontal: 'right',
  },
  transformOrigin: {
    vertical: 'top',
    horizontal: 'left',
  },
};

export function BlockOperationMenu({
  node,
  ...props
}: {
  node: Element;
} & PopoverProps) {
  const optionsRef = React.useRef<HTMLDivElement>(null);
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
  const [subMenuType, setSubMenuType] = useState<null | SubMenuType>(null);

  const subMenuAnchorEl = useMemo(() => {
    if (!subMenuType) return null;
    return optionsRef.current?.querySelector(`[data-submenu-type="${subMenuType}"]`);
  }, [subMenuType]);

  const subMenuOpen = Boolean(subMenuAnchorEl);

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

  const colorOptions = useMemo(
    () => [
      {
        type: SubMenuType.TextColor,
        text: t('editor.textColor'),
        onClick: () => {
          setSubMenuType(SubMenuType.TextColor);
        },
      },
      {
        type: SubMenuType.BackgroundColor,
        text: t('editor.backgroundColor'),
        onClick: () => {
          setSubMenuType(SubMenuType.BackgroundColor);
        },
      },
    ],
    [t]
  );

  const subMenuContent = useMemo(() => {
    switch (subMenuType) {
      case SubMenuType.TextColor:
        return (
          <FontColorPicker
            onChange={(color) => {
              CustomEditor.setBlockColor(editor, node, { font_color: color });
              handleClose();
            }}
          />
        );
      case SubMenuType.BackgroundColor:
        return (
          <BgColorPicker
            onChange={(color) => {
              CustomEditor.setBlockColor(editor, node, { bg_color: color });
              handleClose();
            }}
          />
        );
      default:
        return null;
    }
  }, [editor, node, handleClose, subMenuType]);

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
      <div ref={optionsRef} className={'flex flex-col p-2'}>
        <Typography variant={'body2'} className={'mb-1 text-text-caption'}>
          {t('editor.color')}
        </Typography>
        {colorOptions.map((option, index) => (
          <Button
            data-submenu-type={option.type}
            color={'inherit'}
            onClick={option.onClick}
            size={'small'}
            endIcon={<MoreSvg />}
            className={'w-full justify-between'}
            key={index}
          >
            <div className={'flex-1 text-left'}>{option.text}</div>
          </Button>
        ))}
      </div>
      <Menu
        container={optionsRef.current}
        {...PopoverCommonProps}
        {...subMenuProps}
        open={subMenuOpen}
        anchorEl={subMenuAnchorEl}
        onClose={() => setSubMenuType(null)}
      >
        {subMenuContent}
      </Menu>
    </Popover>
  );
}

export default BlockOperationMenu;
