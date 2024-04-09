import React, { CSSProperties, useEffect, useMemo, useState } from 'react';
import { ReactEditor, useSelected, useSlate } from 'slate-react';
import { Editor, Element, Range } from 'slate';
import { EditorNodeType, HeadingNode } from '$app/application/document/document.types';
import { useTranslation } from 'react-i18next';

function PlaceholderContent({ node, ...attributes }: { node: Element; className?: string; style?: CSSProperties }) {
  const { t } = useTranslation();
  const editor = useSlate();
  const selected = useSelected() && !!editor.selection && Range.isCollapsed(editor.selection);
  const [isComposing, setIsComposing] = useState(false);
  const block = useMemo(() => {
    const path = ReactEditor.findPath(editor, node);
    const match = Editor.above(editor, {
      match: (n) => {
        return !Editor.isEditor(n) && Element.isElement(n) && n.blockId !== undefined && n.type !== undefined;
      },
      at: path,
    });

    if (!match) return null;

    return match[0] as Element;
  }, [editor, node]);

  const className = useMemo(() => {
    return `text-placeholder select-none ${attributes.className ?? ''}`;
  }, [attributes.className]);

  const unSelectedPlaceholder = useMemo(() => {
    switch (block?.type) {
      case EditorNodeType.Paragraph: {
        if (editor.children.length === 1) {
          return t('editor.slashPlaceHolder');
        }

        return '';
      }

      case EditorNodeType.ToggleListBlock:
        return t('blockPlaceholders.bulletList');
      case EditorNodeType.QuoteBlock:
        return t('blockPlaceholders.quote');
      case EditorNodeType.TodoListBlock:
        return t('blockPlaceholders.todoList');
      case EditorNodeType.NumberedListBlock:
        return t('blockPlaceholders.numberList');
      case EditorNodeType.BulletedListBlock:
        return t('blockPlaceholders.bulletList');
      case EditorNodeType.HeadingBlock: {
        const level = (block as HeadingNode).data.level;

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
      case EditorNodeType.CalloutBlock:
      case EditorNodeType.CodeBlock:
        return t('editor.typeSomething');
      default:
        return '';
    }
  }, [block, t, editor.children.length]);

  const selectedPlaceholder = useMemo(() => {
    switch (block?.type) {
      case EditorNodeType.HeadingBlock:
        return unSelectedPlaceholder;
      case EditorNodeType.Page:
        return t('document.title.placeholder');
      case EditorNodeType.GridBlock:
      case EditorNodeType.EquationBlock:
      case EditorNodeType.CodeBlock:
      case EditorNodeType.DividerBlock:
        return '';

      default:
        return t('editor.slashPlaceHolder');
    }
  }, [block?.type, t, unSelectedPlaceholder]);

  useEffect(() => {
    if (!selected) return;

    const handleCompositionStart = () => {
      setIsComposing(true);
    };

    const handleCompositionEnd = () => {
      setIsComposing(false);
    };

    const editorDom = ReactEditor.toDOMNode(editor, editor);

    // placeholder should be hidden when composing
    editorDom.addEventListener('compositionstart', handleCompositionStart);
    editorDom.addEventListener('compositionend', handleCompositionEnd);
    editorDom.addEventListener('compositionupdate', handleCompositionStart);
    return () => {
      editorDom.removeEventListener('compositionstart', handleCompositionStart);
      editorDom.removeEventListener('compositionend', handleCompositionEnd);
      editorDom.removeEventListener('compositionupdate', handleCompositionStart);
    };
  }, [editor, selected]);

  if (isComposing) {
    return null;
  }

  return (
    <span
      placeholder={selected ? selectedPlaceholder : unSelectedPlaceholder}
      contentEditable={false}
      {...attributes}
      className={className}
    />
  );
}

export default PlaceholderContent;
