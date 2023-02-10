export const TrashButton = () => {
  return (
    <button className={'flex w-full items-center rounded-lg px-4 py-2 hover:bg-surface-2'}>
      <img className={'mr-2'} src={'/images/home/trash.svg'} alt={''} />
      <span>Trash</span>
    </button>
  );
};
