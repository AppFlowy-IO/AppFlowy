import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import { Popover } from '@/components/_shared/popover';
import {
  useSelectionToolbarContext,
} from '@/components/editor/components/toolbar/selection-toolbar/SelectionToolbar.hooks';
import { getRangeRect } from '@/components/editor/components/toolbar/selection-toolbar/utils';
import { createHotkey, getModifier, HOT_KEY_NAME } from '@/utils/hotkeys';
import { PopoverPosition } from '@mui/material';
import React, { useCallback, useEffect, useMemo } from 'react';
import ActionButton from './ActionButton';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { ReactComponent as LinkSvg } from '@/assets/link.svg';

export function Href () {
  const { t } = useTranslation();
  const { forceShow } = useSelectionToolbarContext();
  const editor = useSlateStatic() as YjsEditor;
  const hasActivatedInline = CustomEditor.hasMark(editor, EditorMarkFormat.Formula) || CustomEditor.hasMark(editor, EditorMarkFormat.Mention);
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Href);
  const [anchorPosition, setAnchorPosition] = React.useState<undefined | PopoverPosition>(undefined);
  const open = Boolean(anchorPosition);
  const handleClose = useCallback(() => {
    setAnchorPosition(undefined);
  }, []);

  const formatLink = useCallback(() => {
    if (!editor.selection || hasActivatedInline) return;
    const rect = getRangeRect();

    if (!rect) return;
    forceShow(true);

    setAnchorPosition({
      top: rect.top + rect.height,
      left: rect.left + rect.width / 2,
    });
  }, [editor, hasActivatedInline, forceShow]);

  const onClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    formatLink();
  }, [formatLink]);

  const tooltip = useMemo(() => {
    const modifier = getModifier();

    return (
      <>
        <div>{t('editor.link')}</div>
        <div className={'text-xs text-text-caption'}>{`${modifier} + K`}</div>
      </>
    );
  }, [t]);

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (createHotkey(HOT_KEY_NAME.FORMAT_LINK)(e)) {
        e.preventDefault();
        formatLink();
      }
    };

    const slateDom = ReactEditor.toDOMNode(editor, editor);

    if (!slateDom) return;

    slateDom.addEventListener('keydown', onKeyDown);
    return () => {
      slateDom.removeEventListener('keydown', onKeyDown);
    };
  }, [editor, formatLink]);

  return (
    <>
      <ActionButton
        disabled={hasActivatedInline}
        onClick={onClick}
        active={isActivated}
        tooltip={tooltip}
      >
        <LinkSvg />
      </ActionButton>
      {open && <Popover
        onMouseDown={e => e.stopPropagation()}
        onMouseUp={e => e.stopPropagation()}
        disableRestoreFocus={true}
        open={open}
        onClose={handleClose}
        anchorPosition={anchorPosition}
        anchorReference={'anchorPosition'}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'center',
        }}
      >
        <input />
      </Popover>}

    </>
  );
}

export default Href;
