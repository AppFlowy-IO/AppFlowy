export const TrashButton = () => {
  return (
    <button className={'flex items-center px-4 py-2 rounded-lg w-full hover:bg-surface-2'}>
      <img className={'mr-2'} src={'/images/home/trash.svg'} alt={''} />
      <span>Trash</span>
    </button>
  );
};
