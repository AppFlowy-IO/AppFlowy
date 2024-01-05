import React, { useCallback, useMemo, useRef, useState } from 'react';
import { Element } from 'slate';
import { Button, Popover } from '@mui/material';
import ColorLensOutlinedIcon from '@mui/icons-material/ColorLensOutlined';
import { useTranslation } from 'react-i18next';
import { BgColorPicker, FontColorPicker } from '$app/components/editor/components/tools/_shared';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { useSlateStatic } from 'slate-react';
import { PopoverNoBackdropProps } from '$app/components/editor/components/tools/popover';

export function Color({
  node,
  onClose,
}: {
  node: Element & {
    data?: {
      font_color?: string;
      bg_color?: string;
    };
  };
  onClose?: () => void;
}) {
  const { t } = useTranslation();

  const editor = useSlateStatic();

  const ref = useRef<HTMLButtonElement>(null);
  const [open, setOpen] = useState(false);

  const fontColor = useMemo(() => {
    return node.data?.font_color;
  }, [node]);

  const bgColor = useMemo(() => {
    return node.data?.bg_color;
  }, [node]);

  const onColorChange = useCallback(
    (format: 'font_color' | 'bg_color', color: string) => {
      CustomEditor.setBlockColor(editor, node, {
        [format]: color,
      });
      onClose?.();
    },
    [editor, node, onClose]
  );

  return (
    <Button
      ref={ref}
      color={'inherit'}
      onMouseEnter={() => {
        setOpen(true);
      }}
      onMouseLeave={() => {
        setOpen(false);
      }}
      endIcon={<MoreSvg />}
      startIcon={<ColorLensOutlinedIcon />}
      size={'small'}
      className={'mx-2 my-1 justify-start'}
    >
      {t('editor.color')}
      {open && (
        <Popover
          {...PopoverNoBackdropProps}
          anchorOrigin={{
            vertical: 'center',
            horizontal: 'right',
          }}
          PaperProps={{
            ...PopoverNoBackdropProps.PaperProps,
            className: 'w-[200px] max-h-[360px] overflow-x-hidden overflow-y-auto',
          }}
          open={open}
          anchorEl={ref.current}
          onClose={() => {
            setOpen(false);
          }}
        >
          <div className={'flex flex-col'}>
            <FontColorPicker
              onChange={(color) => {
                onColorChange('font_color', color);
              }}
              color={fontColor}
            />
            <BgColorPicker
              onChange={(color) => {
                onColorChange('bg_color', color);
              }}
              color={bgColor}
            />
          </div>
        </Popover>
      )}
    </Button>
  );
}
