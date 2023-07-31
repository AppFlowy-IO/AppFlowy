import React, { useCallback, useMemo } from 'react';
import Popover from '@mui/material/Popover';
import { RangeStaticNoId, TemporaryData, TemporaryState, TemporaryType } from '$app/interfaces/document';
import EquationEditContent from '$app/components/document/_shared/TemporaryInput/EquationEditContent';
import { temporaryActions } from '$app_reducers/document/temporary_slice';
import { rangeActions } from '$app_reducers/document/slice';
import { formatTemporary } from '$app_reducers/document/async-actions/temporary';
import { useAppDispatch } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useSubscribeTemporary } from '$app/components/document/_shared/SubscribeTemporary.hooks';

const AFTER_RENDER_DELAY = 100;

function TemporaryPopover() {
  const temporaryState = useSubscribeTemporary();
  const anchorPosition = useMemo(() => temporaryState?.popoverPosition, [temporaryState]);
  const open = Boolean(anchorPosition);
  const id = temporaryState?.id;
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();

  const onChangeData = useCallback(
    (data: TemporaryData) => {
      dispatch(
        temporaryActions.updateTemporaryState({
          id: docId,
          state: {
            data,
            id,
          },
        })
      );
    },
    [dispatch, docId, id]
  );

  const resetCaret = useCallback(
    (id: string, selection: RangeStaticNoId) => {
      dispatch(
        rangeActions.setCaret({
          docId,
          caret: {
            id,
            index: selection.index + selection.length,
            length: 0,
          },
        })
      );
    },
    [dispatch, docId]
  );

  const onClose = useCallback(() => {
    dispatch(
      temporaryActions.updateTemporaryState({
        id: docId,
        state: {
          id,
          popoverPosition: null,
        },
      })
    );
  }, [dispatch, docId, id]);

  const handleClose = useCallback(() => {
    if (!temporaryState) return;
    onClose();
    dispatch(temporaryActions.deleteTemporaryState(docId));
    resetCaret(temporaryState.id, temporaryState.selection);
  }, [dispatch, docId, onClose, resetCaret, temporaryState]);

  const onConfirm = useCallback(async () => {
    const res = await dispatch(
      formatTemporary({
        controller,
      })
    );
    const state = res.payload as TemporaryState;

    if (!state) return;
    const { id, selection } = state;

    onClose();
    dispatch(rangeActions.clearRanges({ docId }));
    dispatch(temporaryActions.deleteTemporaryState(docId));
    // wait slate to update the dom
    setTimeout(() => {
      resetCaret(id, selection);
    }, AFTER_RENDER_DELAY);
  }, [dispatch, controller, onClose, docId, resetCaret]);

  const renderPopoverContent = useCallback(() => {
    if (!temporaryState) return null;
    const { type, data } = temporaryState;

    switch (type) {
      case TemporaryType.Equation:
        return (
          <EquationEditContent
            value={data.latex}
            onChange={(latex: string) =>
              onChangeData({
                latex,
              })
            }
            onConfirm={onConfirm}
          />
        );
    }
  }, [onChangeData, onConfirm, temporaryState]);

  return (
    <Popover
      onClose={handleClose}
      open={open}
      anchorPosition={anchorPosition ? anchorPosition : undefined}
      onMouseDown={(e) => e.stopPropagation()}
      disableAutoFocus={true}
      disableRestoreFocus={true}
      anchorReference={'anchorPosition'}
      anchorOrigin={{
        vertical: 'bottom',
        horizontal: 'center',
      }}
      transformOrigin={{
        vertical: 'top',
        horizontal: 'center',
      }}
    >
      {renderPopoverContent()}
    </Popover>
  );
}

export default TemporaryPopover;
