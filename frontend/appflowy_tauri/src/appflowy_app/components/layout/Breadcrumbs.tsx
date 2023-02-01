export const Breadcrumbs = () => {
  return (
    <div className={'flex items-center'}>
      <div className={'flex items-center mr-4'}>
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
