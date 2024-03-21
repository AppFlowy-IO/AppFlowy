import React, { useCallback, useRef } from 'react';
import { Element } from 'slate';
import { Popover } from '@mui/material';
import ColorLensOutlinedIcon from '@mui/icons-material/ColorLensOutlined';
import { useTranslation } from 'react-i18next';
import { ColorPicker } from '$app/components/editor/components/tools/_shared';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { useSlateStatic } from 'slate-react';
import { PopoverOrigin } from '@mui/material/Popover/Popover';

const initialOrigin: {
  transformOrigin?: PopoverOrigin;
  anchorOrigin?: PopoverOrigin;
} = {
  anchorOrigin: {
    vertical: 'center',
    horizontal: 'right',
  },
  transformOrigin: {
    vertical: 'center',
    horizontal: 'left',
  },
};

export function Color({
  node,
  openPicker,
  onOpenPicker,
  onClosePicker,
}: {
  node: Element & {
    data?: {
      font_color?: string;
      bg_color?: string;
    };
  };
  openPicker?: boolean;
  onOpenPicker?: () => void;
  onClosePicker?: () => void;
}) {
  const { t } = useTranslation();

  const editor = useSlateStatic();

  const ref = useRef<HTMLDivElement>(null);

  const onColorChange = useCallback(
    (format: 'font_color' | 'bg_color', color: string) => {
      CustomEditor.setBlockColor(editor, node, {
        [format]: color,
      });
      onClosePicker?.();
    },
    [editor, node, onClosePicker]
  );

  return (
    <>
      <div ref={ref} onClick={onOpenPicker} className={'flex w-full items-center justify-between gap-2'}>
        <ColorLensOutlinedIcon className={'h-5 w-5'} />
        <div className={'flex-1'}>{t('editor.color')}</div>
        <MoreSvg className={'h-5 w-5'} />
      </div>
      {openPicker && (
        <Popover
          anchorOrigin={initialOrigin.anchorOrigin}
          transformOrigin={initialOrigin.transformOrigin}
          autoFocus={true}
          open={openPicker}
          onKeyDown={(e) => {
            e.stopPropagation();
            e.nativeEvent.stopImmediatePropagation();
            if (e.key === 'Escape' || e.key === 'ArrowLeft') {
              e.preventDefault();
              onClosePicker?.();
            }
          }}
          onClick={(e) => e.stopPropagation()}
          anchorEl={ref.current}
          onClose={onClosePicker}
        >
          <div className={'flex flex-col'}>
            <ColorPicker onEscape={onClosePicker} onChange={onColorChange} />
          </div>
        </Popover>
      )}
    </>
  );
}
