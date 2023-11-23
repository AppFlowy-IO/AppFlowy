import React from 'react';
import FontSizeConfig from '$app/components/layout/TopBar/FontSizeConfig';
import { useMoreOptionsConfig } from '$app/components/layout/TopBar/MoreOptions.hooks';

function MoreOptions() {
  const { showStyleOptions } = useMoreOptionsConfig();

  return <div className={'flex w-[220px] flex-col'}>{showStyleOptions && <FontSizeConfig />}</div>;
}

export default MoreOptions;
