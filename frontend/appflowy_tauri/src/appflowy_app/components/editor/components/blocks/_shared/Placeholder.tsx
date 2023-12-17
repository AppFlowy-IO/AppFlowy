import React, { CSSProperties, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { Editor, Element, Range } from 'slate';
import { useSelected, useSlate } from 'slate-react';
import { EditorNodeType, HeadingNode } from '$app/application/document/document.types';

function Placeholder({ node, className, style }: { node: Element; className?: string; style?: CSSProperties }) {
  const editor = useSlate();
  const { t } = useTranslation();
  const isEmpty = Editor.isEmpty(editor, node);
  const selected = useSelected() && editor.selection && Range.isCollapsed(editor.selection);

  const unSelectedPlaceholder = useMemo(() => {
    switch (node.type) {
      case EditorNodeType.ToggleListBlock:
        return t('document.plugins.toggleList');
      case EditorNodeType.QuoteBlock:
        return t('editor.quote');
      case EditorNodeType.TodoListBlock:
        return t('document.plugins.todoList');
      case EditorNodeType.NumberedListBlock:
        return t('document.plugins.numberedList');
      case EditorNodeType.BulletedListBlock:
        return t('document.plugins.bulletedList');
      case EditorNodeType.HeadingBlock: {
        const level = (node as HeadingNode).data.level;

        switch (level) {
          case 1:
            return t('editor.mobileHeading1');
          case 2:
            return t('editor.mobileHeading2');
          case 3:
            return t('editor.mobileHeading3');
          default:
            return '';
        }
      }

      default:
        return '';
    }
  }, [node, t]);

  const selectedPlaceholder = useMemo(() => {
    switch (node.type) {
      case EditorNodeType.HeadingBlock:
        return unSelectedPlaceholder;
      default:
        return t('editor.slashPlaceHolder');
    }
  }, [node.type, t, unSelectedPlaceholder]);

  return isEmpty ? (
    <span
      contentEditable={false}
      style={style}
      className={`pointer-events-none absolute left-0.5 top-0 whitespace-nowrap text-text-placeholder ${className}`}
    >
      {selected ? selectedPlaceholder : unSelectedPlaceholder}
    </span>
  ) : null;
}

export default React.memo(Placeholder);
