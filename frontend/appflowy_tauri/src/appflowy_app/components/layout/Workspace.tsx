import { useAppSelector } from '../../store';

export const Workspace = () => {
  const currentUser = useAppSelector((state) => state.currentUser);

  return (
    <div className={'px-2 py-2 flex items-center justify-between'}>
      <button className={'pl-4 flex items-center'}>
        <img className={'mr-2'} src={'/images/home/person.svg'} alt={'user'} />
        <span>{currentUser.displayName}</span>
      </button>
      <button className={'p-2 mr-2 rounded-lg hover:bg-surface-2'}>
        <img src={'/images/home/settings.svg'} alt={'settings'} />
      </button>
    </div>
  );
};
