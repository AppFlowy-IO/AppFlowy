import React, { useMemo, useState } from 'react';
import Popover, { PopoverProps } from '@mui/material/Popover';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';

import { useTranslation } from 'react-i18next';
import { Button, Divider, MenuProps, Menu } from '@mui/material';
import { PopoverCommonProps } from '$app/components/editor/components/tools/popover';
import { Element } from 'slate';
import { useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import FormatColorFillIcon from '@mui/icons-material/FormatColorFill';
import FormatColorTextIcon from '@mui/icons-material/FormatColorText';
import { FontColorPicker, BgColorPicker } from '$app/components/editor/components/tools/_shared';

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
  const formatOptionsRef = React.useRef<HTMLDivElement>(null);
  const editor = useSlateStatic();
  const { t } = useTranslation();
  const [subMenuType, setSubMenuType] = useState<null | SubMenuType>(null);

  const subMenuAnchorEl = useMemo(() => {
    if (!subMenuType) return null;
    return formatOptionsRef.current?.querySelector(`[data-submenu-type="${subMenuType}"]`);
  }, [subMenuType]);

  const subMenuOpen = Boolean(subMenuAnchorEl);

  const operationOptions = useMemo(
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

  const formatOptions = useMemo(
    () => [
      {
        type: SubMenuType.TextColor,
        icon: <FormatColorTextIcon />,
        text: t('editor.textColor'),
        onClick: () => {
          setSubMenuType(SubMenuType.TextColor);
        },
      },
      {
        type: SubMenuType.BackgroundColor,
        icon: <FormatColorFillIcon />,
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
              props.onClose?.({}, 'backdropClick');
            }}
          />
        );
      case SubMenuType.BackgroundColor:
        return (
          <BgColorPicker
            onChange={(color) => {
              CustomEditor.setBlockColor(editor, node, { bg_color: color });
              props.onClose?.({}, 'backdropClick');
            }}
          />
        );
      default:
        return null;
    }
  }, [editor, node, props, subMenuType]);

  return (
    <Popover {...PopoverCommonProps} onMouseDown={(e) => e.stopPropagation()} {...props}>
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
      <div ref={formatOptionsRef} className={'flex flex-col p-2'}>
        {formatOptions.map((option, index) => (
          <Button
            data-submenu-type={option.type}
            color={'inherit'}
            onClick={option.onClick}
            startIcon={option.icon}
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
        container={formatOptionsRef.current}
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
