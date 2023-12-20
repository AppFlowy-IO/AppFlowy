import React, { CSSProperties, useMemo } from 'react';
import { useSelected, useSlateStatic } from 'slate-react';
import { Element } from 'slate';
import { EditorNodeType, HeadingNode } from '$app/application/document/document.types';
import { useTranslation } from 'react-i18next';

function PlaceholderContent({ node, ...attributes }: { node: Element; className?: string; style?: CSSProperties }) {
  const { t } = useTranslation();
  const selected = useSelected();
  const editor = useSlateStatic();
  const justOneParagraph = useMemo(() => {
    return node.type === EditorNodeType.Paragraph && editor.children.length <= 2;
  }, [editor.children.length, node.type]);

  const unSelectedPlaceholder = useMemo(() => {
    switch (node.type) {
      case EditorNodeType.Paragraph: {
        if (justOneParagraph) {
          return t('editor.slashPlaceHolder');
        }

        return '';
      }

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

      case EditorNodeType.Page:
        return t('document.title.placeholder');
      default:
        return '';
    }
  }, [justOneParagraph, node, t]);

  const selectedPlaceholder = useMemo(() => {
    switch (node.type) {
      case EditorNodeType.HeadingBlock:
        return unSelectedPlaceholder;
      case EditorNodeType.Page:
        return t('document.title.placeholder');
      default:
        return t('editor.slashPlaceHolder');
    }
  }, [node.type, t, unSelectedPlaceholder]);

  const className = useMemo(() => {
    return `pointer-events-none absolute left-0.5 top-0 whitespace-nowrap text-text-placeholder ${
      attributes.className ?? ''
    }`;
  }, [attributes.className]);

  return (
    <span contentEditable={false} {...attributes} className={className}>
      {selected ? selectedPlaceholder : unSelectedPlaceholder}
    </span>
  );
}

export default PlaceholderContent;
