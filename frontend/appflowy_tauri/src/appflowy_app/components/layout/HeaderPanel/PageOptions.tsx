import { Button } from '../../_shared/Button';

export const PageOptions = () => {
  return (
    <div className={'flex items-center'}>
      <Button size={'small'} onClick={() => console.log('share click')}>
        Share
      </Button>

      <button className={'ml-8'}>
        <img className={'w-8 h-8'} src={`/images/editor/details.svg`} />
      </button>
    </div>
  );
};
