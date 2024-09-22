import React from 'react';

function EditorSkeleton () {
  return (
    <div className="w-full max-w-[964px] px-6 mt-2">
      <div className="h-10 bg-fill-list-hover w-full mb-4 animate-pulse"></div>
      <div className="h-6 bg-fill-list-hover w-1/2 mb-4 animate-pulse"></div>
      <div className="h-8 bg-fill-list-hover w-3/5 mb-4 animate-pulse"></div>
      <div className="h-7 bg-fill-list-hover w-4/5 mb-4 animate-pulse"></div>
      <div className="h-5 bg-fill-list-hover w-full mb-2 animate-pulse"></div>
      <div className="h-5 bg-fill-list-hover w-full animate-pulse"></div>
    </div>
  );
}

export default EditorSkeleton;
