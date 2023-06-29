import { useAppSelector } from '$app/stores/store';
import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { TEXT_LINK_NAME } from '$app/constants/document/name';

export function useSubscribeLinkPopover() {
  const { docId } = useSubscribeDocument();

  const linkPopover = useAppSelector((state) => {
    return state[TEXT_LINK_NAME][docId];
  });

  return linkPopover;
}
