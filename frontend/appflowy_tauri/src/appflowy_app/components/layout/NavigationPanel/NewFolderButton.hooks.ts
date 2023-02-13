import { useAppDispatch } from '../../../stores/store';
import { foldersActions } from '../../../stores/reducers/folders/slice';
import { nanoid } from 'nanoid';

export const useNewFolder = () => {
  const appDispatch = useAppDispatch();

  const onNewFolder = () => {
    appDispatch(foldersActions.addFolder({ id: nanoid(8), title: 'New Folder 1' }));
  };

  return {
    onNewFolder,
  };
};
