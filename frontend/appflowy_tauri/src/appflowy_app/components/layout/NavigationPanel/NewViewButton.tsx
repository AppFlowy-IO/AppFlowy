import AddSvg from '../../_shared/svg/AddSvg';
import { useNewRootView } from './NewViewButton.hooks';

export const NewViewButton = ({ scrollDown }: { scrollDown: () => void }) => {
  const { onNewRootView } = useNewRootView();

  return (
    <button
      onClick={() => {
        void onNewRootView();
        scrollDown();
      }}
      className={'flex h-[50px] w-full items-center px-6 hover:bg-surface-2'}
    >
      <div className={'mr-2 rounded-full bg-main-accent text-white'}>
        <div className={'h-[24px] w-[24px] text-white'}>
          <AddSvg></AddSvg>
        </div>
      </div>
      <span>New View</span>
    </button>
  );
};
