import { InformationSvg } from '../_shared/svg/InformationSvg';
import { CloseSvg } from '../_shared/svg/CloseSvg';

export const ErrorModal = ({ message, onClose }: { message: string; onClose: () => void }) => {
  return (
    <div className={'fixed inset-0 z-20 flex items-center justify-center bg-white/30 backdrop-blur-sm'}>
      <div className={'relative flex flex-col items-center gap-8 rounded-xl bg-white'}>
        <button onClick={() => onClose()} className={'absolute right-0 top-0 h-8 w-8 px-8 py-8'}>
          <CloseSvg></CloseSvg>
        </button>
        <div className={'h-24 w-24 text-main-alert'}>
          <InformationSvg></InformationSvg>
        </div>
        <h1 className={'text-xl'}>Oops.. something went wrong</h1>
        <h2>{message}</h2>
      </div>
    </div>
  );
};
