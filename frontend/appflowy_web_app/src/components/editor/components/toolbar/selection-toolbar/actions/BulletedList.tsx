import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { getBlockEntry } from '@/application/slate-yjs/utils/yjsOperations';
import { BlockType } from '@/application/types';
import React, { useCallback } from 'react';
import ActionButton from './ActionButton';
import { useTranslation } from 'react-i18next';
import { useSlateStatic } from 'slate-react';
import { ReactComponent as BulletedListSvg } from '@/assets/bulleted_list.svg';

export function BulletedList () {
  const { t } = useTranslation();
  const editor = useSlateStatic() as YjsEditor;
  const isActivated = CustomEditor.isBlockActive(editor, BlockType.BulletedListBlock);

  const onClick = useCallback(() => {
    try {
      const [node] = getBlockEntry(editor);

      if (!node) return;

      if (node.type === BlockType.BulletedListBlock) {
        CustomEditor.turnToBlock(editor, node.blockId as string, BlockType.Paragraph, {});
        return;
      }

      CustomEditor.turnToBlock(editor, node.blockId as string, BlockType.BulletedListBlock, {});

    } catch (e) {
      return;
    }
  }, [editor]);

  return (
    <ActionButton active={isActivated} onClick={onClick} tooltip={t('document.plugins.bulletedList')}>
      <BulletedListSvg />
    </ActionButton>
  );
}

export default BulletedList;
