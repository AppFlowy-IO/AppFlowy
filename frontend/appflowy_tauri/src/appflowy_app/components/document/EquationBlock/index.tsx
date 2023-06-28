import React from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import KatexMath from '$app/components/document/_shared/KatexMath';
import Popover from '@mui/material/Popover';
import EquationEditContent from '$app/components/document/_shared/TemporaryInput/EquationEditContent';
import { useEquationBlock } from '$app/components/document/EquationBlock/useEquationBlock';
import { Functions } from '@mui/icons-material';

function EquationBlock({ node }: { node: NestedBlock<BlockType.EquationBlock> }) {
  const { ref, value, onChange, onOpenPopover, open, anchorPosition, onConfirm, onClosePopover } =
    useEquationBlock(node);

  const formula = open ? value : node.data.formula;

  return (
    <>
      <div
        ref={ref}
        onClick={onOpenPopover}
        className={'flex min-h-[59px] cursor-pointer items-center justify-center overflow-hidden hover:bg-main-selector'}
      >
        {formula ? (
          <KatexMath latex={formula} />
        ) : (
          <span className={'flex text-shade-2'}>
            <Functions />
            <span>Add a TeX equation</span>
          </span>
        )}
      </div>
      <Popover
        transformOrigin={{
          vertical: 'top',
          horizontal: 'center',
        }}
        onMouseDown={(e) => e.stopPropagation()}
        onClose={onClosePopover}
        open={open}
        anchorReference={'anchorPosition'}
        anchorPosition={anchorPosition}
      >
        <EquationEditContent
          placeholder={'c = \\pm\\sqrt{a^2 + b^2\\text{ if }a\\neq 0\\text{ or }b\\neq 0}'}
          multiline={true}
          value={value}
          onChange={onChange}
          onConfirm={onConfirm}
        />
      </Popover>
    </>
  );
}

export default EquationBlock;
