import React, { useCallback, useContext, useRef } from 'react';
import { RangeStaticNoId, TemporaryType } from '$app/interfaces/document';
import { NodeIdContext } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppDispatch } from '$app/stores/store';
import { createTemporary } from '$app_reducers/document/async-actions/temporary';

function LinkInline({
  children,
  getSelection,
  selectedText,
  temporaryType,
  data,
}: {
  getSelection: (node: Element) => RangeStaticNoId | null;
  children: React.ReactNode;
  selectedText: string;
  temporaryType: TemporaryType;
  data: {
    href?: string;
  };
}) {
  const id = useContext(NodeIdContext);
  const { docId } = useSubscribeDocument();
  const ref = useRef<HTMLAnchorElement>(null);
  const dispatch = useAppDispatch();

  const onClick = useCallback(
    async (e: React.MouseEvent) => {
      if (!ref.current) return;
      const selection = getSelection(ref.current);

      if (!selection) return;
      const rect = ref.current?.getBoundingClientRect();

      if (!rect) return;
      e.stopPropagation();
      e.preventDefault();

      await dispatch(
        createTemporary({
          docId,
          state: {
            id,
            selection,
            selectedText,
            type: temporaryType,
            data: {
              href: data.href,
              text: selectedText,
            },
          },
        })
      );
    },
    [data, dispatch, docId, getSelection, id, selectedText, temporaryType]
  );

  return (
    <>
      <span onClick={onClick} ref={ref} className='cursor-pointer text-text-link-default'>
        <span className={' border-b-[1px] border-b-text-link-default'}>{children}</span>
      </span>
    </>
  );
}

export default LinkInline;
