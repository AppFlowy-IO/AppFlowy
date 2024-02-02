import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Typography from '@mui/material/Typography';
import { addMark, removeMark } from 'slate';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { open as openWindow } from '@tauri-apps/api/shell';
import { notify } from '$app/components/editor/components/tools/notify';
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
import LinkEditInput, { pattern } from '$app/components/editor/components/inline_nodes/link/LinkEditInput';

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

    const handleKeyDown = (e: KeyboardEvent) => {
      e.stopPropagation();

      if (e.key === 'Enter') {
        e.preventDefault();
        if (pattern.test(link)) {
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

      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        notify.clear();
        notify.info(`Press Tab to focus on the menu`);
        return;
      }
    };

    input.addEventListener('keydown', handleKeyDown);
    return () => {
      input.removeEventListener('keydown', handleKeyDown);
    };
  }, [link, onClose, setNodeMark]);

  const onConfirm = useCallback(
    (key: string) => {
      if (key === 'open') {
        const linkPrefix = ['http://', 'https://', 'file://', 'ftp://', 'ftps://', 'mailto:'];

        if (linkPrefix.some((prefix) => link.startsWith(prefix))) {
          void openWindow(link);
        } else {
          void openWindow('https://' + link);
        }
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
        disabled: !pattern.test(link),
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
            disableFocus={!focusMenu}
            scrollRef={scrollRef}
            options={editOptions}
            onConfirm={onConfirm}
            onFocus={() => {
              setFocusMenu(true);
            }}
            onBlur={() => {
              setFocusMenu(false);
            }}
            onEscape={onClose}
            disableSelect={!focusMenu}
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
