import React, { useCallback, useContext } from 'react';
import { NodeIdContext } from '$app/components/document/_shared/SubscribeNode.hooks';
import { RangeStaticNoId, TemporaryType } from '$app/interfaces/document';
import { useAppDispatch } from '$app/stores/store';
import { createTemporary } from '$app_reducers/document/async-actions/temporary';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import KatexMath from '$app/components/document/_shared/KatexMath';
import { FakeCursorContainer } from '$app/components/document/_shared/InlineBlock/FakeCursorContainer';

function FormulaInline({
  isFirst,
  isLast,
  children,
  getSelection,
  selectedText,
  data,
}: {
  getSelection: (node: Element) => RangeStaticNoId | null;
  children: React.ReactNode;
  selectedText: string;
  isLast: boolean;
  isFirst: boolean;
  data: {
    latex?: string;
  };
}) {
  const id = useContext(NodeIdContext);
  const { docId } = useSubscribeDocument();
  const dispatch = useAppDispatch();
  const onClick = useCallback(
    (node: HTMLSpanElement) => {
      const selection = getSelection(node);

      if (!selection) return;

      dispatch(
        createTemporary({
          docId,
          state: {
            id,
            selection,
            selectedText,
            type: TemporaryType.Equation,
            data: { latex: data.latex },
          },
        })
      );
    },
    [getSelection, data.latex, dispatch, docId, id, selectedText]
  );

  if (!selectedText) return null;

  return (
    <FakeCursorContainer
      onClick={onClick}
      getSelection={getSelection}
      isFirst={isFirst}
      isLast={isLast}
      renderNode={() => <KatexMath latex={data.latex!} isInline />}
    >
      {children}
    </FakeCursorContainer>
  );
}

export default FormulaInline;
