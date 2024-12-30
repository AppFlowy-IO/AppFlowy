import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import {
  useSelectionToolbarContext,
} from '@/components/editor/components/toolbar/selection-toolbar/SelectionToolbar.hooks';
import { createHotkey, getModifier, HOT_KEY_NAME } from '@/utils/hotkeys';
import React, { useCallback, useEffect, useMemo } from 'react';
import ActionButton from './ActionButton';
import { useTranslation } from 'react-i18next';
import { ReactEditor, useSlate } from 'slate-react';
import { ReactComponent as LinkSvg } from '@/assets/link.svg';
import HrefPopover from '@/components/editor/components/leaf/href/HrefPopover';

export function Href() {
  const { t } = useTranslation();
  const { forceShow } = useSelectionToolbarContext();

  const editor = useSlate() as YjsEditor;

  const {
    visible,
  } = useSelectionToolbarContext();
  const [state, setState] = React.useState({
    isActivated: false,
    hasFormulaActivated: false,
    hasMentionActivated: false,
  });

  const [open, setOpen] = React.useState(false);
  const { isActivated, hasFormulaActivated, hasMentionActivated } = state;

  const getState = useCallback(() => {
    const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Href);
    const hasFormulaActivated = CustomEditor.hasMark(editor, EditorMarkFormat.Formula);
    const hasMentionActivated = CustomEditor.hasMark(editor, EditorMarkFormat.Mention);

    return {
      isActivated,
      hasFormulaActivated,
      hasMentionActivated,
    };
  }, [editor]);

  useEffect(() => {
    if (!visible) return;
    setState(getState());
  }, [visible, getState, editor.selection]);

  const onClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    e.preventDefault();
    setOpen(true);
    forceShow(true);
  }, [forceShow]);

  const tooltip = useMemo(() => {
    const modifier = getModifier();

    return (
      <>
        <div>{t('editor.link')}</div>
        <div className={'text-xs text-text-caption'}>{`${modifier} + K`}</div>
      </>
    );
  }, [t]);

  const disabled = hasFormulaActivated || hasMentionActivated;

  useEffect(() => {
    if (!visible || disabled) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (createHotkey(HOT_KEY_NAME.FORMAT_LINK)(e)) {
        e.preventDefault();
        forceShow(true);
        setOpen(true);
      }
    };

    const slateDom = ReactEditor.toDOMNode(editor, editor);

    if (!slateDom) return;

    slateDom.addEventListener('keydown', onKeyDown);
    return () => {
      slateDom.removeEventListener('keydown', onKeyDown);
    };
  }, [visible, editor, forceShow, disabled]);

  const handleUpdatedSelection = useCallback(() => {
    forceShow(true);
  }, [forceShow]);

  return (
    <>
      <ActionButton
        disabled={disabled}
        onClick={onClick}
        active={isActivated}
        tooltip={tooltip}
      >
        <LinkSvg/>
      </ActionButton>

      <HrefPopover
        open={open}
        updatedSelection={handleUpdatedSelection}
        onClose={() => {
          setOpen(false);
          forceShow(false);
          setState(getState());
        }}
      />
    </>
  );
}

export default Href;
