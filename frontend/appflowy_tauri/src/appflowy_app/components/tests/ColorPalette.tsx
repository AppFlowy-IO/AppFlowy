export const ColorPalette = () => {
  return (
    <div className={'p-8'}>
      <h1 className={'mb-4 text-2xl'}>Colors</h1>
      <h2 className={'mb-4'}>Main</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div title={'main-accent'} className={'m-2 h-[100px] w-[100px] bg-main-accent'}></div>
        <div title={'main-hovered'} className={'m-2 h-[100px] w-[100px] bg-main-hovered'}></div>
        <div title={'main-secondary'} className={'m-2 h-[100px] w-[100px] bg-main-secondary'}></div>
        <div title={'main-selector'} className={'m-2 h-[100px] w-[100px] bg-main-selector'}></div>
        <div title={'main-alert'} className={'m-2 h-[100px] w-[100px] bg-main-alert'}></div>
        <div title={'main-warning'} className={'m-2 h-[100px] w-[100px] bg-main-warning'}></div>
        <div title={'main-success'} className={'m-2 h-[100px] w-[100px] bg-main-success'}></div>
      </div>
      <h2 className={'mb-4'}>Tint</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div title={'tint-1'} className={'m-2 h-[100px] w-[100px] bg-tint-1'}></div>
        <div title={'tint-2'} className={'m-2 h-[100px] w-[100px] bg-tint-2'}></div>
        <div title={'tint-3'} className={'m-2 h-[100px] w-[100px] bg-tint-3'}></div>
        <div title={'tint-4'} className={'m-2 h-[100px] w-[100px] bg-tint-4'}></div>
        <div title={'tint-5'} className={'m-2 h-[100px] w-[100px] bg-tint-5'}></div>
        <div title={'tint-6'} className={'m-2 h-[100px] w-[100px] bg-tint-6'}></div>
        <div title={'tint-7'} className={'m-2 h-[100px] w-[100px] bg-tint-7'}></div>
        <div title={'tint-8'} className={'m-2 h-[100px] w-[100px] bg-tint-8'}></div>
        <div title={'tint-9'} className={'m-2 h-[100px] w-[100px] bg-tint-9'}></div>
      </div>
      <h2 className={'mb-4'}>Shades</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div title={'shade-1'} className={'m-2 h-[100px] w-[100px] bg-shade-1'}></div>
        <div title={'shade-2'} className={'m-2 h-[100px] w-[100px] bg-shade-2'}></div>
        <div title={'shade-3'} className={'m-2 h-[100px] w-[100px] bg-shade-3'}></div>
        <div title={'shade-4'} className={'m-2 h-[100px] w-[100px] bg-shade-4'}></div>
        <div title={'shade-5'} className={'m-2 h-[100px] w-[100px] bg-shade-5'}></div>
        <div title={'shade-6'} className={'m-2 h-[100px] w-[100px] bg-shade-6'}></div>
      </div>
      <h2 className={'mb-4'}>Surface</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div title={'surface-1'} className={'m-2 h-[100px] w-[100px] bg-surface-1'}></div>
        <div title={'surface-2'} className={'m-2 h-[100px] w-[100px] bg-surface-2'}></div>
        <div title={'surface-3'} className={'m-2 h-[100px] w-[100px] bg-surface-3'}></div>
        <div title={'surface-4'} className={'bg-surface-4 m-2 h-[100px] w-[100px]'}></div>
      </div>
    </div>
  );
};
