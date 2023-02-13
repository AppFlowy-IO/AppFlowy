export const FooterPanel = () => {
  return (
    <div className={'flex items-center justify-between px-2 py-2'}>
      <div className={'text-xs text-shade-4'}>
        &copy; 2023 AppFlowy. <a href={'https://github.com/AppFlowy-IO/AppFlowy'}>GitHub</a>
      </div>
      <div>
        <button className={'h-8 w-8 rounded bg-main-secondary text-black'}>?</button>
      </div>
    </div>
  );
};
