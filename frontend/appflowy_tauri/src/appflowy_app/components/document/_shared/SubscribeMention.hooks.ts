import { useSubscribeDocument } from '$app/components/document/_shared/SubscribeDoc.hooks';
import { useAppSelector } from '$app/stores/store';
import { MENTION_NAME } from '$app/constants/document/name';
import { MentionState } from '$app_reducers/document/mention_slice';

const initialState: MentionState = {
  open: false,
  blockId: '',
};

export function useSubscribeMentionState() {
  const { docId } = useSubscribeDocument();

  const state = useAppSelector((state) => {
    return state[MENTION_NAME][docId] || initialState;
  });

  return state;
}
