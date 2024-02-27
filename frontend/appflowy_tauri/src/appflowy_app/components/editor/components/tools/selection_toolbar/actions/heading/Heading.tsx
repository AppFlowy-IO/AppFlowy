import React, { useCallback } from 'react';
import ActionButton from '$app/components/editor/components/tools/selection_toolbar/actions/_shared/ActionButton';
import { ReactComponent as Heading1Svg } from '$app/assets/h1.svg';
import { ReactComponent as Heading2Svg } from '$app/assets/h2.svg';
import { ReactComponent as Heading3Svg } from '$app/assets/h3.svg';
import { useTranslation } from 'react-i18next';
import { CustomEditor } from '$app/components/editor/command';
import { EditorNodeType, HeadingNode } from '$app/application/document/document.types';
import { useSlateStatic } from 'slate-react';
import { getBlock } from '$app/components/editor/plugins/utils';

export function Heading() {
  const { t } = useTranslation();
  const editor = useSlateStatic();
  const toHeading = useCallback(
    (level: number) => {
      return () => {
        CustomEditor.turnToBlock(editor, {
          type: EditorNodeType.HeadingBlock,
          data: {
            level,
          },
        });
      };
    },
    [editor]
  );

  const isActivated = useCallback(
    (level: number) => {
      const node = getBlock(editor) as HeadingNode;

      if (!node) return false;
      const isBlock = CustomEditor.isBlockActive(editor, EditorNodeType.HeadingBlock);

      return isBlock && node.data.level === level;
    },
    [editor]
  );

  return (
    <div className={'flex items-center justify-center'}>
      <ActionButton active={isActivated(1)} tooltip={t('editor.heading1')} onClick={toHeading(1)}>
        <Heading1Svg />
      </ActionButton>
      <ActionButton active={isActivated(2)} tooltip={t('editor.heading2')} onClick={toHeading(2)}>
        <Heading2Svg />
      </ActionButton>
      <ActionButton active={isActivated(3)} tooltip={t('editor.heading3')} onClick={toHeading(3)}>
        <Heading3Svg />
      </ActionButton>
    </div>
  );
}

export default Heading;
