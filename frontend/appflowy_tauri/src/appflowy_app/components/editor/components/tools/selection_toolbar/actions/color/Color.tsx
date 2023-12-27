import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { CustomEditor } from '$app/components/editor/command';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import ColorLensOutlinedIcon from '@mui/icons-material/ColorLensOutlined';
import { addMark } from 'slate';
import { Popover } from '@mui/material';
import { BgColorPicker, FontColorPicker } from '$app/components/editor/components/tools/_shared';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { EditorMarkFormat } from '$app/application/document/document.types';

export function Color({ onClose, onOpen }: { onClose?: () => void; onOpen?: () => void }) {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (open) {
      onOpen?.();
    } else {
      onClose?.();
    }
  }, [onClose, onOpen, open]);
  const isActivated =
    CustomEditor.isMarkActive(editor, EditorMarkFormat.FontColor) ||
    CustomEditor.isMarkActive(editor, EditorMarkFormat.BgColor);

  const handleChange = useCallback(
    (format: EditorMarkFormat.FontColor | EditorMarkFormat.BgColor, color: string) => {
      addMark(editor, format, color);
    },
    [editor]
  );

  const fontColor = useMemo(() => {
    return editor.getMarks()?.[EditorMarkFormat.FontColor];
  }, [editor]);

  const bgColor = useMemo(() => {
    return editor.getMarks()?.[EditorMarkFormat.BgColor];
  }, [editor]);

  return (
    <>
      <ActionButton
        onClick={(e) => {
          e.stopPropagation();
          setOpen(true);
        }}
        tooltip={t('editor.color')}
        active={isActivated}
      >
        <div ref={ref} className={'flex items-center justify-between'}>
          <ColorLensOutlinedIcon className={'w-[14px]'} />
          <MoreSvg className={'rotate-90 transform'} />
        </div>
      </ActionButton>
      {open && (
        <Popover
          open={open}
          anchorEl={ref.current}
          onClose={() => {
            setOpen(false);
          }}
          PaperProps={{
            className: 'w-[200px] max-h-[360px] overflow-x-hidden overflow-y-auto',
          }}
          anchorOrigin={{
            vertical: 'bottom',
            horizontal: 'center',
          }}
          transformOrigin={{
            vertical: 'top',
            horizontal: 'center',
          }}
          onKeyDown={(e) => {
            e.stopPropagation();
          }}
        >
          <FontColorPicker color={fontColor} onChange={(color) => handleChange(EditorMarkFormat.FontColor, color)} />
          <BgColorPicker color={bgColor} onChange={(color) => handleChange(EditorMarkFormat.BgColor, color)} />
        </Popover>
      )}
    </>
  );
}
