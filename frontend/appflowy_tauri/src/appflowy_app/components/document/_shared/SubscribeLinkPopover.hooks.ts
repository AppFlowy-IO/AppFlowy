import { useAppSelector } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';

export function useSubscribeLinkPopover() {
  const { docId } = useSubscribeDocument();

  const linkPopover = useAppSelector((state) => {
    return state.documentLinkPopover[docId];
  });

  return linkPopover;
}
