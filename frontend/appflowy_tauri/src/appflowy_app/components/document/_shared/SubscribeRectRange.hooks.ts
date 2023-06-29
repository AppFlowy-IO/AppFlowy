import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';
import { RECT_RANGE_NAME } from '$app/constants/document/name';

export function useSubscribeRectRange() {
  const { docId } = useSubscribeDocument();
  const rectRange = useAppSelector((state) => {
    return state[RECT_RANGE_NAME][docId];
  });

  return rectRange;
}
