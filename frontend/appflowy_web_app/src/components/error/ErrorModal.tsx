import { ReactComponent as InformationSvg } from '@/assets/information.svg';
import { ReactComponent as CloseSvg } from '$icons/16x/close.svg';
import { Button } from '@mui/material';

export const ErrorModal = ({ message, onClose }: { message: string; onClose: () => void }) => {
  return (
    <div className={'fixed inset-0 z-10 flex items-center justify-center bg-white/30 backdrop-blur-sm'}>
      <div
        className={
          'border-shade-5 relative flex flex-col items-center gap-8 rounded-xl border bg-white px-16 py-8 shadow-md'
        }
      >
        <button
          onClick={() => onClose()}
          className={'absolute right-0 top-0 z-10 px-2 py-2 text-text-caption hover:text-text-title'}
        >
          <CloseSvg className={'h-8 w-8'} />
        </button>
        <div className={'text-main-alert'}>
          <InformationSvg className={'h-24 w-24'} />
        </div>
        <h1 className={'text-xl'}>Oops.. something went wrong</h1>
        <h2>{message}</h2>

        <Button
          onClick={() => {
            window.location.reload();
          }}
        >
          Reload
        </Button>
      </div>
    </div>
  );
};
