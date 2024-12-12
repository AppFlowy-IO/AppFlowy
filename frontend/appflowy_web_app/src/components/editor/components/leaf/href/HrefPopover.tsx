import React, { useCallback, useEffect, useMemo, useRef } from 'react';
import { Button, Divider, OutlinedInput, PopoverPosition } from '@mui/material';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { ReactComponent as RemoveIcon } from '@/assets/trash.svg';
import { Popover } from '@/components/_shared/popover';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { useTranslation } from 'react-i18next';
import { getRangeRect } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import { YjsEditor } from '@/application/slate-yjs';
import { createHotkey, HOT_KEY_NAME } from '@/utils/hotkeys';
import { debounce } from 'lodash-es';
import { PopoverOrigin } from '@mui/material/Popover/Popover';
import { processUrl } from '@/utils/url';

const defaultOrigin: PopoverOrigin = {
  vertical: 'top',
  horizontal: 'center',
};

interface HrefPopoverProps {
  open: boolean;
  onClose: () => void;
  updatedSelection?: () => void;
}

function HrefPopover({
  open,
  onClose,
  updatedSelection,
}: HrefPopoverProps) {
  const editor = useSlateStatic() as YjsEditor;
  const { t } = useTranslation();
  const [isActivated, setIsActivated] = React.useState(CustomEditor.isMarkActive(editor, EditorMarkFormat.Href));
  const [popoverType, setPopoverType] = React.useState<'add' | 'update' | undefined>(undefined);
  const [anchorPosition, setAnchorPosition] = React.useState<undefined | PopoverPosition>(undefined);

  useEffect(() => {
    if (isActivated) {
      setPopoverType('update');
    } else {
      setPopoverType('add');
    }
  }, [isActivated]);

  useEffect(() => {
    if (open) {
      setIsActivated(CustomEditor.isMarkActive(editor, EditorMarkFormat.Href));
      const rect = getRangeRect();

      if (!rect) return;
      setUrlValid(true);
      setAnchorPosition({
        top: rect.bottom + 10,
        left: rect.left,
      });
    }
  }, [open, editor]);

  const handleClose = useCallback(() => {
    setAnchorPosition(undefined);
    onClose();

    window.getSelection()?.removeAllRanges();

    setTimeout(() => {
      ReactEditor.focus(editor);
    }, 50);
  }, [editor, onClose]);

  const formatLink = useCallback((value: string) => {
    CustomEditor.addMark(editor, {
      key: EditorMarkFormat.Href,
      value,
    });
    handleClose();
    setIsActivated(true);
  }, [editor, handleClose]);

  const updateText = useCallback((value: string) => {
    const { selection } = editor;

    if (!selection) return;
    const texts = CustomEditor.getTextNodes(editor);
    const hrefNode = texts.find(n => {
      if (n.href) return true;
    });

    if (!hrefNode) return;
    const href = hrefNode.href;

    editor.delete();
    editor.insertText(value);

    const newSelection = editor.selection;

    if (!newSelection) return;

    const end = editor.end(newSelection);

    editor.select({
      anchor: {
        path: end.path,
        offset: end.offset - value.length,
      },
      focus: end,
    });

    CustomEditor.addMark(editor, {
      key: EditorMarkFormat.Href,
      value: href || '',
    });

    updatedSelection?.();
    setIsActivated(true);

  }, [editor, updatedSelection]);

  const removeLink = useCallback(() => {
    CustomEditor.removeMark(editor, EditorMarkFormat.Href);
    handleClose();
    setIsActivated(false);
  }, [editor, handleClose]);

  const urlRef = useRef<HTMLInputElement | null>(null);
  const textRef = useRef<HTMLInputElement | null>(null);
  const buttonRef = useRef<HTMLButtonElement | null>(null);
  const [urlValid, setUrlValid] = React.useState(true);
  const addLink = useMemo(() => {
    if (!open || popoverType !== 'add') return null;
    return (
      <div className={'flex flex-col gap-2'}>
        <OutlinedInput
          autoFocus={true}
          error={!urlValid}
          onKeyDown={e => {
            if (!urlValid) return;
            if (createHotkey(HOT_KEY_NAME.ENTER)(e.nativeEvent)) {
              e.preventDefault();
              e.stopPropagation();
              formatLink(e.currentTarget.value);
            }
          }}
          onInput={e => {
            const target = e.target as HTMLInputElement;
            const url = processUrl(target.value);

            if (!url) {
              setUrlValid(false);
              return;
            }

            setUrlValid(true);
          }}
          size={'small'} fullWidth={true} placeholder={t('toolbar.addLink')}/>
        {urlValid ? null : (
          <div className={'text-function-error text-xs'}>
            {t('editor.incorrectLink')}
          </div>
        )}
      </div>
    );
  }, [formatLink, open, popoverType, t, urlValid]);

  const updateLink = useMemo(() => {
    if (!open || popoverType !== 'update') return null;
    const texts = CustomEditor.getTextNodes(editor);
    const hrefNode = texts.find(n => {
      if (n.href) return true;
    });

    if (!hrefNode || !editor.selection) return null;

    const text = editor.string(editor.selection);

    return (
      <div className={'flex flex-col gap-4'}>
        <div className={'flex flex-col gap-1'}>
          <div className={'text-text-caption text-xs'}>URL</div>
          <OutlinedInput
            autoFocus={true}
            error={!urlValid}
            inputRef={(input: HTMLInputElement) => {
              urlRef.current = input;
            }}
            defaultValue={hrefNode.href}
            onBlur={e => {
              if (e.target.value === hrefNode.href || !urlValid) return;
              CustomEditor.addMark(editor, {
                key: EditorMarkFormat.Href,
                value: e.currentTarget.value,
              });
            }}
            onInput={e => {
              const target = e.target as HTMLInputElement;
              const url = processUrl(target.value);

              if (!url) {
                setUrlValid(false);
                return;
              }

              setUrlValid(true);
            }}
            onKeyDown={e => {
              if (!urlValid) return;
              if (createHotkey(HOT_KEY_NAME.ENTER)(e.nativeEvent)) {
                e.preventDefault();
                e.stopPropagation();
                formatLink(e.currentTarget.value);
              } else if (createHotkey(HOT_KEY_NAME.DOWN)(e.nativeEvent)) {
                e.preventDefault();
                e.stopPropagation();
                textRef.current?.focus();
              }
            }}
            size={'small'}
            fullWidth={true}
            placeholder={t('toolbar.addLink')}
          />
          {urlValid ? null : (
            <div className={'text-function-error text-xs'}>
              {t('editor.incorrectLink')}
            </div>
          )}
        </div>
        <div className={'flex flex-col gap-1'}>
          <div className={'text-text-caption text-xs'}>{t('editor.text')}</div>
          <OutlinedInput
            inputRef={(input: HTMLInputElement) => {
              textRef.current = input;
            }}
            onKeyDown={e => {
              if (createHotkey(HOT_KEY_NAME.UP)(e.nativeEvent)) {
                e.preventDefault();
                e.stopPropagation();
                urlRef.current?.focus();
              }
            }}
            defaultValue={text}
            onInput={e => {
              const target = e.target as HTMLInputElement;

              if (target.value) {
                updateText(target.value);
              }
            }}
            size={'small'}
            fullWidth={true} placeholder={t('toolbar.addLink')}/>
        </div>
        <Divider/>
        <Button
          ref={buttonRef} onClick={removeLink} startIcon={<RemoveIcon/>} size={'small'}
          className={'w-full hover:text-function-error justify-start'}
          color={'inherit'}>
          {t('document.inlineLink.removeLink')}
        </Button>
      </div>
    );
  }, [urlValid, open, popoverType, editor, t, removeLink, formatLink, updateText]);

  const paperRef = useRef<HTMLDivElement | null>(null);

  const debouncePosition = useMemo(() => {
    return debounce(() => {

      if (!anchorPosition || !paperRef.current) return;
      const paperRect = paperRef.current.getBoundingClientRect();

      if (anchorPosition.top + paperRect.height > window.innerHeight) {
        setAnchorPosition({
          top: anchorPosition.top - paperRect.height - 30,
          left: anchorPosition.left,
        });
        return;
      }

    }, 50);
  }, [anchorPosition]);

  return (
    <Popover
      onMouseDown={e => e.stopPropagation()}
      onMouseUp={e => e.stopPropagation()}
      disableRestoreFocus={true}
      open={open && !!anchorPosition}
      onClose={handleClose}
      adjustOrigins={false}
      anchorPosition={anchorPosition}
      anchorReference={'anchorPosition'}
      transformOrigin={defaultOrigin}
      slotProps={{
        paper: {
          className: 'p-4 min-w-[360px]',
          ref: paperRef,
        },
      }}
      onTransitionEnd={debouncePosition}
    >
      {popoverType && (
        popoverType === 'add' ? addLink : updateLink
      )}
    </Popover>
  );
}

export default HrefPopover;