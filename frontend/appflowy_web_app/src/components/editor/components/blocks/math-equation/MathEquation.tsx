import KatexMath from '@/components/_shared/katex-math/KatexMath';
import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { EditorElementProps, MathEquationNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import { ReactComponent as MathSvg } from '@/assets/math.svg';
import React, { forwardRef, memo, useMemo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

export const MathEquation = memo(
  forwardRef<HTMLDivElement, EditorElementProps<MathEquationNode>>(
    ({ node, children, className, ...attributes }, ref) => {
      const formula = node.data.formula;
      const { t } = useTranslation();
      const containerRef = useRef<HTMLDivElement>(null);
      const [showToolbar, setShowToolbar] = useState(false);
      const newClassName = useMemo(() => {
        const classList = [
          className,
          'math-equation-block relative w-full container-bg w-full py-1  select-none rounded',
        ];

        if (formula) {
          classList.push('border border-transparent hover:border-line-divider hover:bg-fill-list-active cursor-pointer');
        }

        return classList.join(' ');
      }, [formula, className]);

      return (
        <>
          <div
            {...attributes}
            ref={containerRef}
            contentEditable={false}
            onMouseEnter={() => {
              if (!formula) return;
              setShowToolbar(true);
            }}
            onMouseLeave={() => setShowToolbar(false)}
            className={newClassName}
          >
            {formula ? (
              <KatexMath latex={formula} />
            ) : (
              <div
                className={
                  'flex h-[48px] w-full items-center gap-[10px] rounded border border-line-divider bg-fill-list-active px-4 text-text-caption'
                }
              >
                <MathSvg className={'h-4 w-4'} />
                {t('document.plugins.mathEquation.addMathEquation')}
              </div>
            )}
            <div ref={ref} className={'absolute left-0 top-0 h-full w-full caret-transparent'}>
              {children}
            </div>
            {showToolbar && (
              <RightTopActionsToolbar
                onCopy={async () => {
                  if (!formula) return;
                  try {
                    await copyTextToClipboard(formula);
                    notify.success(t('publish.copy.mathBlock'));
                  } catch (_) {
                    // do nothing
                  }
                }}
              />
            )}
          </div>
        </>
      );
    }
  ),
  (prevProps, nextProps) => JSON.stringify(prevProps.node) === JSON.stringify(nextProps.node)
);

export default MathEquation;
