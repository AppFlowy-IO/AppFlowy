import { YjsEditor } from '@/application/slate-yjs';
import { CustomEditor } from '@/application/slate-yjs/command';
import { BlockType } from '@/application/types';
import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, ToggleListNode } from '@/components/editor/editor.type';
import { useTranslation } from 'react-i18next';
import { useReadOnly, useSlateStatic } from 'slate-react';

export const ToggleList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ToggleListNode>>(({ node, children, ...attributes }, ref) => {
    const blockId = node.blockId;
    const editor = useSlateStatic() as YjsEditor;
    const { collapsed, level = 0 } = useMemo(() => node.data || {}, [node.data]);
    const { t } = useTranslation();
    const readOnly = useReadOnly();
    const className = useMemo(() => {

      const classList = ['flex w-full flex-col'];

      if (attributes.className) {
        classList.push(attributes.className);
      }

      if (collapsed) {
        classList.push('collapsed');
      }

      if (level) {
        classList.push(`toggle-heading level-${level}`);
      }

      return classList.join(' ');

    }, [collapsed, level, attributes.className]);

    return (
      <>
        <div
          {...attributes}
          ref={ref}
          className={className}
        >
          {children}
          {!readOnly && !collapsed && node.children.slice(1).length === 0 &&
            <div
              onClick={() => {
                CustomEditor.addChildBlock(editor, blockId, BlockType.Paragraph, {});
              }}
              contentEditable={false}
              className={'text-text-caption select-none text-sm hover:bg-fill-list-hover rounded-[6px] cursor-pointer flex items-center h-[36px] px-[0.5em] ml-[1.45em]'}
            >
              {
                level === 0 ?
                  t('document.plugins.emptyToggleList') :
                  t('document.plugins.emptyToggleHeadingWeb', { level })
              }
            </div>
          }
        </div>
      </>
    );
  }),
);

export default ToggleList;
