import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { EditorMarkFormat } from '@/application/slate-yjs/types';
import ActionButton from '@/components/editor/components/toolbar/selection-toolbar/actions/ActionButton';
import React, { useCallback } from 'react';
import { useTranslation } from 'react-i18next';
import { Transforms, Text, Editor } from 'slate';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as MathSvg } from '@/assets/math.svg';

function Formula () {
  const { t } = useTranslation();
  const editor = useSlateStatic() as YjsEditor;
  const isActivated = CustomEditor.isMarkActive(editor, EditorMarkFormat.Formula);

  const onClick = useCallback(() => {
    const { selection } = editor;

    if (!selection) return;

    if (!isActivated) {
      const start = editor.start(selection);
      const text = editor.string(selection);

      editor.delete();

      editor.insertText('$');

      const newSelection = editor.selection;

      if (!newSelection) {
        console.error('newSelection is undefined');
        return;
      }

      Transforms.select(editor, {
        anchor: start,
        focus: newSelection.focus,
      });
      CustomEditor.addMark(editor, {
        key: EditorMarkFormat.Formula,
        value: text,
      });
    } else {
      const [entry] = editor.nodes({
        at: selection,
        match: n => !Editor.isEditor(n) && Text.isText(n) && n.formula !== undefined,
      });

      if (!entry) return;

      const [node] = entry;
      const formula = (node as unknown as Text).formula || '';

      CustomEditor.removeMark(editor, EditorMarkFormat.Formula);

      editor.delete();
      editor.insertText(formula);
    }

  }, [editor, isActivated]);

  return (
    <ActionButton
      onClick={onClick}
      active={isActivated}
      tooltip={t('document.plugins.createInlineMathEquation')}
    >
      <MathSvg />
    </ActionButton>
  );
}

export default Formula;