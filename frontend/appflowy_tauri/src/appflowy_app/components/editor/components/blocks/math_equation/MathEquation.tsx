import { forwardRef, memo, useState } from 'react';
import { EditorElementProps, MathEquationNode } from '$app/application/document/document.types';
import KatexMath from '$app/components/_shared/KatexMath';
import { useTranslation } from 'react-i18next';
import { FunctionsOutlined } from '@mui/icons-material';
import EditPopover from '$app/components/editor/components/blocks/math_equation/EditPopover';

export const MathEquation = memo(
  forwardRef<HTMLDivElement, EditorElementProps<MathEquationNode>>(
    ({ node, children, className, ...attributes }, ref) => {
      const formula = node.data.formula;
      const { t } = useTranslation();
      const [anchorEl, setAnchorEl] = useState<HTMLDivElement | null>(null);
      const open = Boolean(anchorEl);

      return (
        <>
          <div
            contentEditable={false}
            ref={ref}
            {...attributes}
            onClick={(e) => {
              setAnchorEl(e.currentTarget);
            }}
            className={`${
              className ?? ''
            } relative cursor-pointer rounded border border-line-divider bg-content-blue-50 px-3 `}
          >
            {formula ? (
              <KatexMath latex={formula} />
            ) : (
              <div className={'relative flex h-[48px] w-full items-center gap-[10px] text-text-caption'}>
                <FunctionsOutlined />
                {t('document.plugins.mathEquation.addMathEquation')}
              </div>
            )}
            <div className={'invisible absolute'}>{children}</div>
          </div>
          {open && (
            <EditPopover
              onClose={() => {
                setAnchorEl(null);
              }}
              node={node}
              open={open}
              anchorEl={anchorEl}
            />
          )}
        </>
      );
    }
  )
);
