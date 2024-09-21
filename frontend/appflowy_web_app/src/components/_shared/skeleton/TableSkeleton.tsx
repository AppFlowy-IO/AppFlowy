import React from 'react';

const TableSkeleton = ({ rows = 5, columns = 4 }) => {
  return (
    <div className="overflow-x-auto shadow-md sm:rounded-lg mt-4">
      <table className="w-full text-sm text-left text-gray-500">
        <thead className="text-xs text-gray-700 uppercase bg-fill-list-hover dark:text-gray-400">
        <tr>
          {[...Array(columns)].map((_, index) => (
            <th key={`header-${index}`} scope="col" className="px-6 py-3">
              <div className="h-6 bg-fill-list-hover rounded w-24 animate-pulse"></div>
            </th>
          ))}
        </tr>
        </thead>
        <tbody>
        {[...Array(rows)].map((_, rowIndex) => (
          <tr key={`row-${rowIndex}`} className="bg-bg-body border-b border-line-divider">
            {[...Array(columns)].map((_, colIndex) => (
              <td key={`cell-${rowIndex}-${colIndex}`} className="px-6 py-4">
                <div
                  className={`h-5 bg-fill-list-hover rounded ${colIndex === 0 ? 'w-14' : 'w-24'} animate-pulse`}
                ></div>
              </td>
            ))}
          </tr>
        ))}
        </tbody>
      </table>
    </div>
  );
};

export default TableSkeleton;