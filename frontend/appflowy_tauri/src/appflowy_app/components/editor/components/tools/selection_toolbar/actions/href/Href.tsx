import React, { useCallback, useEffect, useMemo } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlateStatic } from 'slate-react';
import { CustomEditor } from '$app/components/editor/command';
import { ReactComponent as LinkSvg } from '$app/assets/link.svg';
import { Editor, Range } from 'slate';
import { EditorMarkFormat } from '$app/application/document/document.types';
import { useDecorateDispatch, useDecorateState } from '$app/components/editor/stores';
import { LinkEditPopover } from '$app/components/editor/components/inline_nodes/link';
import isHotkey from 'is-hotkey';
import { getModifier } from '$app/utils/hotkeys';

export function Href() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const isActivatedInline = CustomEditor.isInlineActive(editor);
  const isActivated = !isActivatedInline && CustomEditor.isMarkActive(editor, EditorMarkFormat.Href);

  const decorateState = useDecorateState('link');
  const openEditPopover = !!decorateState;
  const anchorPosition = useMemo(() => {
    const range = decorateState?.range;

    if (!range) return;

    const domRange = ReactEditor.toDOMRange(editor, range);

    const rect = domRange.getBoundingClientRect();

    return {
      top: rect.top,
      left: rect.left,
      height: rect.height,
    };
  }, [decorateState?.range, editor]);

  const defaultHref = useMemo(() => {
    const range = decorateState?.range;

    if (!range) return '';

    const marks = Editor.marks(editor);

    return marks?.href || Editor.string(editor, range);
  }, [decorateState?.range, editor]);

  const { add: addDecorate, clear: clearDecorate } = useDecorateDispatch();
  const onClick = useCallback(() => {
    if (!editor.selection) return;
    addDecorate({
      range: editor.selection,
      class_name: 'bg-content-blue-100 rounded',
      type: 'link',
    });
  }, [addDecorate, editor]);

  const handleEditPopoverClose = useCallback(() => {
    const range = decorateState?.range;

    clearDecorate();
    if (range) {
      ReactEditor.focus(editor);
      editor.select(range);
    }
  }, [clearDecorate, decorateState?.range, editor]);

  useEffect(() => {
    const editorDom = ReactEditor.toDOMNode(editor, editor);
    const handleShortcut = (e: KeyboardEvent) => {
      if (isHotkey('mod+k', e)) {
        if (editor.selection && Range.isCollapsed(editor.selection)) return;
        e.preventDefault();
        e.stopPropagation();
        onClick();
      }
    };

    editorDom.addEventListener('keydown', handleShortcut);
    return () => {
      editorDom.removeEventListener('keydown', handleShortcut);
    };
  }, [editor, onClick]);

  const tooltip = useMemo(() => {
    const modifier = getModifier();

    return (
      <>
        <div>{t('editor.link')}</div>
        <div className={'text-xs text-text-caption'}>{`${modifier} + K`}</div>
      </>
    );
  }, [t]);

  return (
    <>
      <ActionButton disabled={isActivatedInline} onClick={onClick} active={isActivated} tooltip={tooltip}>
        <LinkSvg />
      </ActionButton>
      {openEditPopover && (
        <LinkEditPopover
          open={openEditPopover}
          anchorPosition={anchorPosition}
          anchorReference={'anchorPosition'}
          onClose={handleEditPopoverClose}
          defaultHref={defaultHref}
        />
      )}
    </>
  );
}

export default Href;
