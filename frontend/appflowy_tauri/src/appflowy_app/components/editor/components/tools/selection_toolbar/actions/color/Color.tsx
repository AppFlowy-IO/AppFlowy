import React, { useCallback, useMemo, useRef, useState } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { CustomEditor } from '$app/components/editor/command';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import ColorLensOutlinedIcon from '@mui/icons-material/ColorLensOutlined';
import { ReactComponent as MoreSvg } from '$app/assets/more.svg';
import { EditorMarkFormat } from '$app/application/document/document.types';
import debounce from 'lodash-es/debounce';
import ColorPopover from './ColorPopover';

export function Color(_: { onOpen?: () => void; onClose?: () => void }) {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLButtonElement>(null);

  const isActivated =
    CustomEditor.isMarkActive(editor, EditorMarkFormat.FontColor) ||
    CustomEditor.isMarkActive(editor, EditorMarkFormat.BgColor);
  const debouncedClose = useMemo(
    () =>
      debounce(() => {
        setOpen(false);
      }, 200),
    []
  );

  const handleOpen = useCallback(() => {
    debouncedClose.cancel();
    setOpen(true);
  }, [debouncedClose]);

  return (
    <>
      <ActionButton
        ref={ref}
        onMouseEnter={handleOpen}
        onMouseLeave={debouncedClose}
        tooltip={t('editor.color')}
        active={isActivated}
      >
        <div className={'flex items-center justify-between'}>
          <ColorLensOutlinedIcon className={'w-[14px]'} />
          <MoreSvg className={'rotate-90 transform'} />
        </div>
      </ActionButton>
      {open && ref.current && (
        <ColorPopover open={open} onOpen={handleOpen} anchorEl={ref.current} debounceClose={debouncedClose} />
      )}
    </>
  );
}
