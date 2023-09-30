import { useAppDispatch, useAppSelector } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { updatePageIcon } from '$app_reducers/pages/async_actions';
import { useCallback, useMemo } from 'react';
import { ViewIconTypePB } from '@/services/backend';
import { CoverType } from '$app/interfaces/document';
import { updateNodeDataThunk } from '$app_reducers/document/async-actions';
import { useSubscribeNode } from '$app/components/document/_shared/SubscribeNode.hooks';
export const heightCls = {
  cover: 'h-[220px]',
  icon: 'h-[80px]',
  coverAndIcon: 'h-[250px]',
  none: 'h-0',
};

export function useDocumentBanner(id: string) {
  const dispatch = useAppDispatch();
  const { docId, controller } = useSubscribeDocument();
  const icon = useAppSelector((state) => state.pages.pageMap[docId]?.icon);
  const { node } = useSubscribeNode(id);
  const { cover, coverType } = node.data;

  const onUpdateIcon = useCallback(
    (icon: string) => {
      dispatch(
        updatePageIcon({
          id: docId,
          icon: icon
            ? {
                ty: ViewIconTypePB.Emoji,
                value: icon,
              }
            : undefined,
        })
      );
    },
    [dispatch, docId]
  );

  const onUpdateCover = useCallback(
    (coverType: CoverType | null, cover: string | null) => {
      dispatch(
        updateNodeDataThunk({
          id,
          data: {
            coverType: coverType || '',
            cover: cover || '',
          },
          controller,
        })
      );
    },
    [controller, dispatch, id]
  );

  const className = useMemo(() => {
    if (cover && icon) return heightCls.coverAndIcon;
    if (cover) return heightCls.cover;
    if (icon) return heightCls.icon;
    return heightCls.none;
  }, [cover, icon]);

  return {
    onUpdateCover,
    onUpdateIcon,
    className,
    icon,
    cover,
    coverType,
    node,
  };
}
