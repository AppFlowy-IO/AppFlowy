import React, { useEffect, useState } from 'react';
import TabbarSkeleton from '@/components/_shared/skeleton/TabbarSkeleton';
import TitleSkeleton from '@/components/_shared/skeleton/TitleSkeleton';

function GridSkeleton ({ includeTitle = true, includeTabs = true }: { includeTitle?: boolean; includeTabs?: boolean }) {
  const [rows, setRows] = useState(3);
  const columns = 10;

  useEffect(() => {
    const updateRows = () => {
      setRows(Math.max(Math.ceil(window.innerHeight / 100), 3));
    };

    updateRows();
    window.addEventListener('resize', updateRows);
    return () => window.removeEventListener('resize', updateRows);
  }, []);

  return (
    <div className={`w-full overflow-x-auto ${includeTitle ? 'py-2 px-6' : ''}`}>
      {includeTitle && (
        <>
          <div className="w-full my-6 flex items-center h-20 mb-2">
            <TitleSkeleton />
          </div>

        </>
      )}

      {includeTabs && <div className="w-full flex items-center h-10 mb-2">
        <TabbarSkeleton />
      </div>}
      <div className="w-full mt-2">
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead>
            <tr>
              {[...Array(columns)].map((_, index) => (
                <th key={index} className="px-6 py-3 border-b border-line-divider bg-bg-base">
                  <div className="h-6 bg-fill-list-hover rounded animate-pulse"></div>
                </th>
              ))}
            </tr>
            </thead>
            <tbody>
            {[...Array(rows)].map((_, rowIndex) => (
              <tr key={rowIndex}>
                {[...Array(columns)].map((_, colIndex) => (
                  <td key={colIndex} className="px-6 py-4 border-b border-line-divider">
                    <div className="h-5 bg-fill-list-hover rounded animate-pulse"></div>
                  </td>
                ))}
              </tr>
            ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

export default GridSkeleton;