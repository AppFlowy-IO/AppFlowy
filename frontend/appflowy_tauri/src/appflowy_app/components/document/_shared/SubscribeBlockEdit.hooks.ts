import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';
import { BLOCK_EDIT_NAME } from '$app/constants/document/name';

export function useSubscribeBlockEditState() {
  const { docId } = useSubscribeDocument();
  const blockEditState = useAppSelector((state) => state[BLOCK_EDIT_NAME][docId]);

  return blockEditState;
}

export function useEditingState(id: string) {
  const blockEditState = useSubscribeBlockEditState();

  return blockEditState?.id === id && blockEditState?.editing;
}
