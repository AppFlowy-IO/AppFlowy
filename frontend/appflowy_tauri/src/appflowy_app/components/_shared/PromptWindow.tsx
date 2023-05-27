import { Button } from '$app/components/_shared/Button';

export const PromptWindow = ({ msg, onYes, onCancel }: { msg: string; onYes: () => void; onCancel: () => void }) => {
  return (
    <div
      className='fixed inset-0 z-20 flex items-center justify-center bg-black/30 backdrop-blur-sm'
      onClick={() => onCancel()}
    >
      <div className={'rounded-xl bg-white p-16'} onClick={(e) => e.stopPropagation()}>
        <div className={'flex flex-col items-center justify-center gap-8'}>
          <div className={'text-black'}>{msg}</div>
          <div className={'flex items-center justify-around gap-4'}>
            <Button onClick={() => onCancel()} size={'medium-transparent'}>
              Cancel
            </Button>
            <Button onClick={() => onYes()} size={'medium'}>
              Yes
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};
