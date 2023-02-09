export const TestColors = () => {
  return (
    <div>
      <h2 className={'mb-4'}>Main</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div className={'m-2 h-[100px] w-[100px] bg-main-accent'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-main-hovered'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-main-secondary'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-main-selector'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-main-alert'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-main-warning'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-main-success'}></div>
      </div>
      <h2 className={'mb-4'}>Tint</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-1'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-2'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-3'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-4'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-5'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-6'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-7'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-8'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-tint-9'}></div>
      </div>
      <h2 className={'mb-4'}>Shades</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div className={'m-2 h-[100px] w-[100px] bg-shade-1'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-shade-2'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-shade-3'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-shade-4'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-shade-5'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-shade-6'}></div>
      </div>
      <h2 className={'mb-4'}>Surface</h2>
      <div className={'mb-8 flex flex-wrap items-center'}>
        <div className={'m-2 h-[100px] w-[100px] bg-surface-1'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-surface-2'}></div>
        <div className={'m-2 h-[100px] w-[100px] bg-surface-3'}></div>
        <div className={'bg-surface-4 m-2 h-[100px] w-[100px]'}></div>
      </div>
    </div>
  );
};
