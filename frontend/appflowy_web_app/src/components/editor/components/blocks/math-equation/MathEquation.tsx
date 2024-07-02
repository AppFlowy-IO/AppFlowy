import KatexMath from '@/components/_shared/katex-math/KatexMath';
import { notify } from '@/components/_shared/notify';
import RightTopActionsToolbar from '@/components/editor/components/block-actions/RightTopActionsToolbar';
import { EditorElementProps, MathEquationNode } from '@/components/editor/editor.type';
import { copyTextToClipboard } from '@/utils/copy';
import { FunctionsOutlined } from '@mui/icons-material';
import React, { forwardRef, memo, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';

export const MathEquation = memo(
  forwardRef<HTMLDivElement, EditorElementProps<MathEquationNode>>(
    ({ node, children, className, ...attributes }, ref) => {
      const formula = node.data.formula;
      const { t } = useTranslation();
      const containerRef = useRef<HTMLDivElement>(null);
      const [showToolbar, setShowToolbar] = useState(false);

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
            className={`${className} math-equation-block relative w-full ${
              formula ? 'cursor-pointer' : 'cursor-default'
            } container-bg w-full select-none rounded border border-transparent py-2 px-3 hover:border-line-divider hover:bg-fill-list-active`}
          >
            {formula ? (
              <KatexMath latex={formula} />
            ) : (
              <div className={'flex h-[48px] w-full items-center gap-[10px] text-text-caption'}>
                <FunctionsOutlined />
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
