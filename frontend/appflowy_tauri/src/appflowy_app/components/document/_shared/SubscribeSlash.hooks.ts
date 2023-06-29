import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';
import { SLASH_COMMAND_NAME } from '$app/constants/document/name';

export function useSubscribeSlashState() {
  const { docId } = useSubscribeDocument();

  const slashCommandState = useAppSelector((state) => {
    return state[SLASH_COMMAND_NAME][docId];
  });

  return slashCommandState;
}
