export const PluginsButton = () => {
  return (
    <button className={'flex items-center px-4 py-2 rounded-lg w-full hover:bg-surface-2'}>
      <img className={'mr-2 w-[24px] h-[24px]'} src={'/images/home/page.svg'} alt={''} />
      <span>Plugins</span>
    </button>
  );
};
