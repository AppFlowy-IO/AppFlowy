import { DeleteForeverOutlined } from '@mui/icons-material';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';

export const TrashButton = () => {
  return (
    <button className={'flex w-full items-center rounded-lg px-4 py-2 text-text-title hover:bg-fill-active'}>
      <span className={'h-[23px] w-[23px]'}>
        <TrashSvg />
      </span>
      <span className={'ml-2'}>Trash</span>
    </button>
  );
};
