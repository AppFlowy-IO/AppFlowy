import { currentUserActions } from '../../stores/reducers/current-user/slice';
import { useAppDispatch, useAppSelector } from '../../stores/store';

export const useAuth = () => {
  const dispatch = useAppDispatch();

  const currentUser = useAppSelector((state) => state.currentUser);

  function logout() {
    dispatch(currentUserActions.logout());
  }

  return { currentUser, logout };
};
