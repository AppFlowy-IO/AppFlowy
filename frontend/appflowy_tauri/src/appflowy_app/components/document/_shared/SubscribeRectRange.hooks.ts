import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';

export function useSubscribeRectRange() {
  const { docId } = useSubscribeDocument();
  const rectRange = useAppSelector((state) => {
    return state.documentRectSelection[docId];
  });
  return rectRange;
}
