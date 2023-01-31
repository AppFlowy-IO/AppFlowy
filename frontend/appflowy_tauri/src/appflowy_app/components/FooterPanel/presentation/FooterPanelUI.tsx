export const FooterPanelUI = () => {
  return (
    <div className={'flex items-center justify-between px-2 py-2'}>
      <div className={'text-shade-3'}>
        &copy; 2023 AppFlowy. <a href={'https://github.com/AppFlowy-IO/AppFlowy'}>GitHub</a>
      </div>
      <div>
        <button className={'w-8 h-8 bg-main-secondary text-black rounded'}>?</button>
      </div>
    </div>
  );
};
