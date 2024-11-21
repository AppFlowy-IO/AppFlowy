import { BlockType } from '@/application/types';
import { ReactComponent as MathSvg } from '@/assets/math.svg';
import { KatexMath } from '@/components/_shared/katex-math';
import { usePopoverContext } from '@/components/editor/components/block-popover/BlockPopoverContext';
import MathEquationToolbar from '@/components/editor/components/blocks/math-equation/MathEquationToolbar';
import { EditorElementProps, MathEquationNode } from '@/components/editor/editor.type';
import React, { forwardRef, memo, Suspense, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useReadOnly } from 'slate-react';

export const MathEquation = memo(
  forwardRef<HTMLDivElement, EditorElementProps<MathEquationNode>>(
    ({ node, children, className, ...attributes }, ref) => {
      const formula = node.data.formula;
      const readOnly = useReadOnly();
      const { t } = useTranslation();
      const containerRef = useRef<HTMLDivElement>(null);
      const [showToolbar, setShowToolbar] = useState(false);
      const newClassName = useMemo(() => {
        const classList = [
          className,
          'w-full bg-bg-body py-2',
        ];

        if (!readOnly) {
          classList.push('cursor-pointer');
        }

        return classList.join(' ');
      }, [className, readOnly]);
      const {
        openPopover,
      } = usePopoverContext();

      return (
        <>
          <div
            {...attributes}
            ref={containerRef}
            contentEditable={readOnly ? false : undefined}
            onMouseEnter={() => {
              if (!formula) return;
              setShowToolbar(true);
            }}
            onMouseLeave={() => setShowToolbar(false)}
            className={newClassName}
            onClick={e => {
              if (!readOnly) {
                e.preventDefault();
                e.stopPropagation();
                openPopover(node.blockId, BlockType.EquationBlock, e.currentTarget);
              }
            }}
          >
            <div
              contentEditable={false}
              className={`embed-block ${formula ? 'p-0.5' : 'p-4'}`}
            >
              {formula ? (
                <div className={'flex items-center w-full justify-center'}>
                  <Suspense fallback={formula}>
                    <KatexMath latex={formula} />
                  </Suspense>
                </div>

              ) : (
                <div className={'flex items-center gap-4 text-text-caption'}>
                  <MathSvg className={'h-6 w-6'} />
                  {t('document.plugins.mathEquation.addMathEquation')}
                </div>
              )}
            </div>

            <div
              ref={ref}
              className={'absolute h-full w-full caret-transparent'}
            >
              {children}
            </div>
            {showToolbar && (
              <MathEquationToolbar node={node} />
            )}
          </div>
        </>
      );
    },
  ),
  (prevProps, nextProps) => JSON.stringify(prevProps.node) === JSON.stringify(nextProps.node),
);

export default MathEquation;
