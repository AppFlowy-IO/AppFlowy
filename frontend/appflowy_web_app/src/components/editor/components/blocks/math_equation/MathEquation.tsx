import KatexMath from '@/components/_shared/katex-math/KatexMath';
import { EditorElementProps, MathEquationNode } from '@/components/editor/editor.type';
import { FunctionsOutlined } from '@mui/icons-material';
import { forwardRef, memo, useRef } from 'react';
import { useTranslation } from 'react-i18next';

export const MathEquation = memo(
  forwardRef<HTMLDivElement, EditorElementProps<MathEquationNode>>(
    ({ node, children, className, ...attributes }, ref) => {
      const formula = node.data.formula;
      const { t } = useTranslation();
      const containerRef = useRef<HTMLDivElement>(null);

      return (
        <>
          <div
            {...attributes}
            ref={containerRef}
            className={`${className} math-equation-block relative w-full cursor-pointer py-2`}
          >
            <div
              contentEditable={false}
              className={`container-bg w-full select-none rounded border border-line-divider bg-content-blue-50 px-3`}
            >
              {formula ? (
                <KatexMath latex={formula} />
              ) : (
                <div className={'flex h-[48px] w-full items-center gap-[10px] text-text-caption'}>
                  <FunctionsOutlined />
                  {t('document.plugins.mathEquation.addMathEquation')}
                </div>
              )}
            </div>
            <div ref={ref} className={'absolute left-0 top-0 h-full w-full caret-transparent'}>
              {children}
            </div>
          </div>
        </>
      );
    }
  )
);

export default MathEquation;
