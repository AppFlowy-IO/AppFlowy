import React, { useCallback, useState } from 'react';
import { BlockType, NestedBlock } from '$app/interfaces/document';
import KatexMath from '$app/components/document/_shared/KatexMath';
import EquationEditContent from '$app/components/document/_shared/TemporaryInput/EquationEditContent';
import { Functions } from '@mui/icons-material';
import { useBlockPopover } from '$app/components/document/_shared/BlockPopover/BlockPopover.hooks';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppDispatch } from '$app/stores/store';

function EquationBlock({ node }: { node: NestedBlock<BlockType.EquationBlock> }) {
  const formula = node.data.formula;
  const [value, setValue] = useState(formula);
  const { controller } = useSubscribeDocument();
  const id = node.id;
  const dispatch = useAppDispatch();

  const onChange = useCallback((newVal: string) => {
    setValue(newVal);
  }, []);

  const onAfterOpen = useCallback(() => {
    setValue(formula);
  }, [formula]);

  const onConfirm = useCallback(async () => {
    await dispatch(
      updateNodeDataThunk({
        id,
        data: {
          formula: value,
        },
        controller,
      })
    );
  }, [dispatch, id, value, controller]);

  const renderContent = useCallback(
    ({ onClose }: { onClose: () => void }) => {
      return (
        <EquationEditContent
          placeholder={'c = \\pm\\sqrt{a^2 + b^2\\text{ if }a\\neq 0\\text{ or }b\\neq 0}'}
          multiline={true}
          value={value}
          onChange={onChange}
          onConfirm={async () => {
            await onConfirm();
            onClose();
          }}
        />
      );
    },
    [value, onChange, onConfirm]
  );

  const { open, contextHolder, openPopover, anchorElRef } = useBlockPopover({
    id: node.id,
    renderContent,
    onAfterOpen,
  });
  const displayFormula = open ? value : formula;

  return (
    <>
      <div
        ref={anchorElRef}
        onClick={openPopover}
        className={'my-1 flex min-h-[59px] cursor-pointer flex-col overflow-hidden rounded hover:bg-main-secondary'}
      >
        {displayFormula ? (
          <KatexMath latex={displayFormula} />
        ) : (
          <div className={'flex h-[100%] w-[100%] flex-1 items-center bg-main-selector px-1 text-shade-2'}>
            <Functions />
            <span>Add a TeX equation</span>
          </div>
        )}
      </div>
      {contextHolder}
    </>
  );
}

export default EquationBlock;
