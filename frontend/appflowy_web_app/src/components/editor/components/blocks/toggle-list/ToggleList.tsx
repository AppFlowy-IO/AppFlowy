import React, { forwardRef, memo, useMemo } from 'react';
import { EditorElementProps, ToggleListNode } from '@/components/editor/editor.type';
import { useTranslation } from 'react-i18next';

export const ToggleList = memo(
  forwardRef<HTMLDivElement, EditorElementProps<ToggleListNode>>(({ node, children, ...attributes }, ref) => {
    const { collapsed, level = 0 } = useMemo(() => node.data || {}, [node.data]);
    const { t } = useTranslation();
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
          {node.children.slice(1).length === 0 &&
            <div className={'text-text-caption h-[28px] pl-[1.75em]'}>{t('togg')}</div>}
        </div>
      </>
    );
  }),
);

export default ToggleList;
