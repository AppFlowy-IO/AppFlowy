import { useAppDispatch } from '../../../store';
import { foldersActions } from '../../../redux/folders/slice';
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
