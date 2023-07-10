import React, { useCallback, useContext } from 'react';
import { NodeIdContext } from '$app/components/document/_shared/SubscribeNode.hooks';
import { useTextLink } from '$app/components/document/_shared/TextLink/TextLink.hooks';
import EditLinkToolbar from '$app/components/document/_shared/TextLink/EditLinkToolbar';
import { useAppDispatch } from '$app/stores/store';
import { linkPopoverActions } from '$app_reducers/document/slice';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

function TextLink({
  getSelection,
  title,
  href,
  children,
}: {
  getSelection: (node: Element) => {
    index: number;
    length: number;
  } | null;
  children: React.ReactNode;
  href: string;
  title: string;
}) {
  const blockId = useContext(NodeIdContext);
  const { editing, ref, onMouseEnter, onMouseLeave } = useTextLink(blockId);
  const dispatch = useAppDispatch();
  const { docId } = useSubscribeDocument();

  const onEdit = useCallback(() => {
    if (!ref.current) return;
    const selection = getSelection(ref.current);

    if (!selection) return;
    const rect = ref.current?.getBoundingClientRect();

    if (!rect) return;
    dispatch(
      linkPopoverActions.setLinkPopover({
        docId,
        linkState: {
          anchorPosition: {
            top: rect.top + rect.height,
            left: rect.left + rect.width / 2,
          },
          id: blockId,
          selection,
          title,
          href,
          open: true,
        },
      })
    );
  }, [blockId, dispatch, docId, getSelection, href, ref, title]);

  if (!blockId) return null;

  return (
    <>
      <a
        onMouseLeave={onMouseLeave}
        onMouseEnter={onMouseEnter}
        ref={ref}
        href={href}
        target='_blank'
        rel='noopener noreferrer'
        className='cursor-pointer text-text-link-default'
      >
        <span className={' border-b-[1px] border-b-text-link-default '}>{children}</span>
      </a>
      {ref.current && (
        <EditLinkToolbar
          editing={editing}
          href={href}
          onMouseLeave={onMouseLeave}
          onMouseEnter={onMouseEnter}
          linkElement={ref.current}
          blockId={blockId}
          onEdit={onEdit}
        />
      )}
    </>
  );
}

export default TextLink;
