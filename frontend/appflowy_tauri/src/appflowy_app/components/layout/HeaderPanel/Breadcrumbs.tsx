import { ShowMenuSvg } from '../../_shared/svg/ShowMenuSvg';

export const Breadcrumbs = ({ menuHidden, onShowMenuClick }: { menuHidden: boolean; onShowMenuClick: () => void }) => {
  return (
    <div className={'flex items-center'}>
      <div className={'mr-4 flex items-center'}>
        {menuHidden && (
          <button onClick={() => onShowMenuClick()} className={'mr-2 h-5 w-5'}>
            <ShowMenuSvg></ShowMenuSvg>
          </button>
        )}

        <button className={'p-1'} onClick={() => history.back()}>
          <img src={'/images/home/arrow_left.svg'} />
        </button>
        <button className={'p-1'}>
          <img src={'/images/home/arrow_right.svg'} />
        </button>
      </div>
      <div className={'flex items-center'}>
        <span className={'mr-8'}>Getting Started</span>
        <span className={'mr-8'}>/</span>
        <span className={'mr-8'}>Read Me</span>
      </div>
    </div>
  );
};
