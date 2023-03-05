import { useAppSelector } from '../../stores/store';
import { useWorkspace } from './Workspace.hooks';
import { useEffect } from 'react';

export const WorkspaceUser = () => {
  const currentUser = useAppSelector((state) => state.currentUser);
  const { loadWorkspaceItems } = useWorkspace();
  useEffect(() => {
    void (async () => {
      await loadWorkspaceItems();
    })();
  }, [currentUser.isAuthenticated]);

  return (
    <div className={'flex items-center justify-between px-2 py-2'}>
      <button className={'flex items-center pl-4'}>
        <img className={'mr-2'} src={'/images/home/person.svg'} alt={'user'} />
        <span>{currentUser.displayName}</span>
      </button>
      <button className={'mr-2 rounded-lg p-2 hover:bg-surface-2'}>
        <img src={'/images/home/settings.svg'} alt={'settings'} />
      </button>
    </div>
  );
};
