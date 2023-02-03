import AddSvg from '../../_shared/AddSvg';
import { useNewFolder } from './NewFolderButton.hooks';

export const NewFolderButton = () => {
  const { onNewFolder } = useNewFolder();

  return (
    <button onClick={() => onNewFolder()} className={'flex items-center w-full hover:bg-surface-2 px-6 h-[50px]'}>
      <div className={'bg-main-accent rounded-full text-white mr-2'}>
        <div className={'text-white w-[24px] h-[24px]'}>
          <AddSvg></AddSvg>
        </div>
      </div>
      <span>New Folder</span>
    </button>
  );
};
