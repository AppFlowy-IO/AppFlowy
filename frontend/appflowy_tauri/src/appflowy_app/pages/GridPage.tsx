import { useParams, Link } from 'react-router-dom';

import AddSvg from '../components/_shared/AddSvg';

export const GridPage = () => {
  const params = useParams();

  console.log({ params });

  return (
    <div className='flex flex-col gap-12 mt-24 mx-auto  w-[calc(100%-200px)]'>
      {/* view type */}
      <h1 className='text-4xl font-bold'>Grid</h1>

      {/* page title */}
      <p className='text-2xl font-semibold'>👋 Welcome to AppFlowy</p>

      <div className='flex justify-between  w-full'>
        {/* View title */}
        <h2 className='text-xl font-semibold'>My plans on week</h2>

        <div className='flex gap-4'>
          <div>
            <span className='flex'>
              <span className='w-8 h-8 '>
                <AddSvg />
              </span>
              <button>
                <Link to='/'>Add View</Link>
              </button>
            </span>
          </div>

          <div>
            <div className='relative'>
              <span className='absolute inset-y-0 left-0 flex items-center pl-3'>
                <svg
                  xmlns='http://www.w3.org/2000/svg'
                  width='24'
                  height='24'
                  viewBox='0 0 24 24'
                  fill='none'
                  stroke='currentColor'
                  strokeWidth='2'
                  strokeLinecap='round'
                  strokeLinejoin='round'
                >
                  <circle cx='11' cy='11' r='8'></circle>
                  <line x1='21' y1='21' x2='16.65' y2='16.65'></line>
                </svg>
              </span>
              <input
                className='block w-full pl-10 pr-3   border border-none  rounded-md leading-5 bg-white placeholder-gray-400 focus:outline-none focus:placeholder-gray-500 sm:text-sm'
                placeholder='Search'
                type='search'
              />
            </div>
          </div>
        </div>
      </div>

      {/* table component view with text area for td */}
      <div className='flex flex-col gap-4'>
        <table className=' w-full table-fixed'>
          <thead>
            <tr>
              <th className='border-l-0 border-2  border-slate-100  p-4  '>Todo</th>
              <th className=' border-2  border-slate-100  p-4  '>Status</th>
              <th className=' border-2  border-slate-100  p-4  '>Description</th>
              <th className=' border-2  border-slate-100  p-4  '>Due Date</th>
              <th className='border-r-0 border-2  border-slate-100  p-4  '>
                <div className='flex items-center cursor-pointer text-gray-500 hover:text-black'>
                  <span className='w-8 h-8'>
                    <AddSvg />
                  </span>
                  New column
                </div>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td className=' border-2 border-l-0  border-slate-100  p-2   h-[50px] '>Create new Landing page</td>
              <td className=' border-2  border-slate-100  p-2  h-[50px]'>
                Design and implement a new landing page for the company
              </td>
              <td className=' border-2  border-slate-100  p-2  h-[50px]'>
                <span className='bg-orange-300 rounded p-1'>In progress</span>
              </td>
              <td className=' border-2  border-slate-100  p-2  h-[50px]'>{new Date().toLocaleDateString()}</td>
              <td className='border-r-0 border-2  border-slate-100  p-2  h-[50px]'></td>
            </tr>
            <tr>
              <td className=' border-l-0 border-2 border-slate-100  p-2  h-[50px]'>Design new logo</td>
              <td className=' border-2 border-slate-100  p-2  h-[50px]'>
                Design and implement a new logo for the company
              </td>
              <td className=' border-2 border-slate-100  p-2  h-[50px]'>
                <span className='bg-green-300 rounded p-1'>Done</span>
              </td>
              <td className=' border-2 border-slate-100  p-2  h-[50px]'>{new Date().toLocaleDateString()}</td>
              <td className='border-r-0 border-2  border-slate-100  p-2  h-[50px]'></td>
            </tr>
            <tr>
              <td className='border-l-0 border-2 border-slate-100  p-2 h-[50px]'></td>
              <td className=' border-2 border-slate-100  p-2  h-[50px]'></td>
              <td className=' border-2 border-slate-100  p-2  h-[50px]'></td>
              <td className=' border-2 border-slate-100  p-2  h-[50px]'></td>
              <td className='border-r-0 border-2  border-slate-100  p-2  h-[50px]'></td>
            </tr>
          </tbody>
        </table>
        <div>
          <div className='flex items-center cursor-pointer text-gray-500 hover:text-black'>
            <span className='w-8 h-8'>
              <AddSvg />
            </span>
            New row
          </div>
        </div>
      </div>

      <span className=' '>
        Count : <span className='font-semibold'>2</span>
      </span>
    </div>
  );
};
