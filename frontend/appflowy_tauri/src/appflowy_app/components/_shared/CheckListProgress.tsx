export const CheckListProgress = ({ completed, max }: { completed: number; max: number }) => {
  return (
    <div className={'flex w-full items-center gap-4'}>
      {max > 0 && (
        <>
          <div className={'flex flex-1 gap-1'}>
            {completed > 0 &&
              Array(completed)
                .fill(0)
                .map((item, index) => (
                  <div key={index} className={'h-[4px] flex-1 flex-shrink-0 rounded bg-main-accent'}></div>
                ))}
            {max - completed > 0 &&
              Array(max - completed)
                .fill(0)
                .map((item, index) => (
                  <div key={index} className={'h-[4px] flex-1 flex-shrink-0 rounded bg-tint-9'}></div>
                ))}
          </div>
          <div className={'text-xs text-shade-4'}>{((100 * completed) / max).toFixed(0)}%</div>
        </>
      )}
    </div>
  );
};
