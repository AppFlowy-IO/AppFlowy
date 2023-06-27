import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';
import { TemporaryState } from '$app/interfaces/document';
import { TEMPORARY_NAME } from '$app/constants/document/name';

export function useSubscribeTemporary(): TemporaryState {
  const { docId } = useSubscribeDocument();
  const temporaryState = useAppSelector((state) => state[TEMPORARY_NAME][docId]);

  return temporaryState;
}
