import { forwardRef, memo, useEffect, useRef, useState } from 'react';
import { EditorElementProps, MathEquationNode } from '$app/application/document/document.types';
import KatexMath from '$app/components/_shared/katex_math/KatexMath';
import { useTranslation } from 'react-i18next';
import { FunctionsOutlined } from '@mui/icons-material';
import EditPopover from '$app/components/editor/components/blocks/math_equation/EditPopover';
import { ReactEditor, useSelected, useSlateStatic } from 'slate-react';

export const MathEquation = memo(
  forwardRef<HTMLDivElement, EditorElementProps<MathEquationNode>>(
    ({ node, children, className, ...attributes }, ref) => {
      const formula = node.data.formula;
      const { t } = useTranslation();
      const containerRef = useRef<HTMLDivElement>(null);
      const [open, setOpen] = useState(false);

      const selected = useSelected();

      const editor = useSlateStatic();

      useEffect(() => {
        const slateDom = ReactEditor.toDOMNode(editor, editor);

        if (!slateDom) return;
        const handleKeyDown = (e: KeyboardEvent) => {
          if (e.key === 'Enter') {
            e.preventDefault();
            e.stopPropagation();
            setOpen(true);
          }
        };

        if (selected) {
          slateDom.addEventListener('keydown', handleKeyDown);
        }

        return () => {
          slateDom.removeEventListener('keydown', handleKeyDown);
        };
      }, [editor, selected]);

      return (
        <>
          <div
            {...attributes}
            ref={containerRef}
            onClick={() => {
              setOpen(true);
            }}
            className={`${className} relative w-full cursor-pointer py-2`}
          >
            <div
              contentEditable={false}
              className={`w-full select-none rounded border border-line-divider ${
                selected ? 'border-fill-hover' : ''
              } bg-content-blue-50 px-3`}
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
          {open && (
            <EditPopover
              onClose={() => {
                setOpen(false);
              }}
              node={node}
              open={open}
              anchorEl={containerRef.current}
            />
          )}
        </>
      );
    }
  )
);
