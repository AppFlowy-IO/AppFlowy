import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Typography from '@mui/material/Typography';
import { addMark, removeMark } from 'slate';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { notify } from 'src/appflowy_app/components/_shared/notify';
import { CustomEditor } from '$app/components/editor/command';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as RemoveSvg } from '$app/assets/delete.svg';
import { ReactComponent as LinkSvg } from '$app/assets/link.svg';
import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import isHotkey from 'is-hotkey';
import LinkEditInput from '$app/components/editor/components/inline_nodes/link/LinkEditInput';
import { openUrl, isUrl } from '$app/utils/open_url';

function LinkEditContent({ onClose, defaultHref }: { onClose: () => void; defaultHref: string }) {
  const editor = useSlateStatic();
  const { t } = useTranslation();
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Href);

  const [focusMenu, setFocusMenu] = useState<boolean>(false);
  const scrollRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLElement>(null);
  const [link, setLink] = useState<string>(defaultHref);

  const setNodeMark = useCallback(() => {
    if (link === '') {
      removeMark(editor, EditorMarkFormat.Href);
    } else {
      addMark(editor, EditorMarkFormat.Href, link);
    }
  }, [editor, link]);

  const removeNodeMark = useCallback(() => {
    onClose();
    editor.removeMark(EditorMarkFormat.Href);
  }, [editor, onClose]);

  useEffect(() => {
    const input = inputRef.current;

    if (!input) return;

    let isComposing = false;

    const handleCompositionUpdate = () => {
      isComposing = true;
    };

    const handleCompositionEnd = () => {
      isComposing = false;
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      e.stopPropagation();

      if (e.key === 'Enter') {
        e.preventDefault();
        if (isUrl(link)) {
          onClose();
          setNodeMark();
        }

        return;
      }

      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
        return;
      }

      if (e.key === 'Tab') {
        e.preventDefault();
        setFocusMenu(true);
        return;
      }

      if (!isComposing && (e.key === 'ArrowDown' || e.key === 'ArrowUp')) {
        notify.clear();
        notify.info(`Press Tab to focus on the menu`);
        return;
      }
    };

    input.addEventListener('compositionstart', handleCompositionUpdate);
    input.addEventListener('compositionend', handleCompositionEnd);
    input.addEventListener('compositionupdate', handleCompositionUpdate);
    input.addEventListener('keydown', handleKeyDown);
    return () => {
      input.removeEventListener('keydown', handleKeyDown);
      input.removeEventListener('compositionstart', handleCompositionUpdate);
      input.removeEventListener('compositionend', handleCompositionEnd);
      input.removeEventListener('compositionupdate', handleCompositionUpdate);
    };
  }, [link, onClose, setNodeMark]);

  const onConfirm = useCallback(
    (key: string) => {
      if (key === 'open') {
        openUrl(link);
      } else if (key === 'copy') {
        void navigator.clipboard.writeText(link);
        notify.success(t('message.copy.success'));
      } else if (key === 'remove') {
        removeNodeMark();
      }
    },
    [link, removeNodeMark, t]
  );

  const renderOption = useCallback((icon: React.ReactNode, label: string) => {
    return (
      <div key={label} className={'flex items-center gap-2'}>
        {icon}
        <div className={'flex-1'}>{label}</div>
      </div>
    );
  }, []);

  const editOptions: KeyboardNavigationOption[] = useMemo(() => {
    return [
      {
        key: 'open',
        disabled: !isUrl(link),
        content: renderOption(<LinkSvg className={'h-4 w-4'} />, t('editor.openLink')),
      },
      {
        key: 'copy',
        content: renderOption(<CopySvg className={'h-4 w-4'} />, t('editor.copyLink')),
      },
      {
        key: 'remove',
        content: renderOption(<RemoveSvg className={'h-4 w-4'} />, t('editor.removeLink')),
      },
    ];
  }, [link, renderOption, t]);

  return (
    <>
      {!isActivated && (
        <Typography className={'w-full justify-start pb-2 font-medium'}>{t('editor.addYourLink')}</Typography>
      )}
      <LinkEditInput link={link} setLink={setLink} inputRef={inputRef} />

      <div ref={scrollRef} className={'mt-1 flex w-full flex-col items-start'}>
        {isActivated && (
          <KeyboardNavigation
            options={editOptions}
            disableFocus={!focusMenu}
            scrollRef={scrollRef}
            onConfirm={onConfirm}
            onFocus={() => {
              setFocusMenu(true);
            }}
            onBlur={() => {
              setFocusMenu(false);
            }}
            disableSelect={!focusMenu}
            onEscape={onClose}
            onKeyDown={(e) => {
              e.stopPropagation();
              if (isHotkey('Tab', e)) {
                e.preventDefault();
                setFocusMenu(false);
                inputRef.current?.focus();
              }
            }}
          />
        )}
      </div>
    </>
  );
}

export default LinkEditContent;
