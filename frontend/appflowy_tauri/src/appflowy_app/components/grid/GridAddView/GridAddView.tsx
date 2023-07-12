import AddSvg from '../../_shared/svg/AddSvg';

export const GridAddView = () => {
  return (
    <button className='flex cursor-pointer items-center rounded-lg p-2 text-sm hover:bg-fill-list-hover'>
      <i className='mr-2 h-5 w-5'>
        <AddSvg />
      </i>
      <span>Add View</span>
    </button>
  );
};
