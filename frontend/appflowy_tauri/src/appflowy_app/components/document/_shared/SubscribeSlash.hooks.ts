import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';

export function useSubscribeSlashState() {
  const { docId } = useSubscribeDocument();

  const slashCommandState = useAppSelector((state) => {
    return state.documentSlashCommand[docId];
  });

  return slashCommandState;
}
