export const PluginsButton = () => {
  return (
    <button className={'flex w-full items-center rounded-lg px-4 py-2 hover:bg-surface-2'}>
      <img className={'mr-2 h-[24px] w-[24px]'} src={'/images/home/page.svg'} alt={''} />
      <span>Plugins</span>
    </button>
  );
};
