import AddSvg from '../_shared/svg/AddSvg';

export const NewBoardBlock = ({ onClick }: { onClick: () => void }) => {
  return (
    <div className={'w-[250px]'}>
      <button onClick={onClick} className={'flex w-full items-center gap-2 rounded-lg px-4 py-2 hover:bg-surface-2'}>
        <span className={'h-5 w-5'}>
          <AddSvg></AddSvg>
        </span>
        <span>Add Block</span>
      </button>
    </div>
  );
};
