import { KatexMath } from '@/components/_shared/katex-math';
import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { EditorElementProps, MathEquationNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import { ReactComponent as MathSvg } from '@/assets/math.svg';
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
          'w-full bg-bg-body py-2 math-equation-block',
        ];

        return classList.join(' ');
      }, [className]);

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
              className={'absolute left-0 top-0 h-full w-full caret-transparent'}
            >
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
    },
  ),
  (prevProps, nextProps) => JSON.stringify(prevProps.node) === JSON.stringify(nextProps.node),
);

export default MathEquation;
