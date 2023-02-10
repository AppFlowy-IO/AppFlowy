import AddSvg from '../../_shared/svg/AddSvg';
import { useNewFolder } from './NewFolderButton.hooks';

export const NewFolderButton = () => {
  const { onNewFolder } = useNewFolder();

  return (
    <button onClick={() => onNewFolder()} className={'flex h-[50px] w-full items-center px-6 hover:bg-surface-2'}>
      <div className={'mr-2 rounded-full bg-main-accent text-white'}>
        <div className={'h-[24px] w-[24px] text-white'}>
          <AddSvg></AddSvg>
        </div>
      </div>
      <span>New Folder</span>
    </button>
  );
};
