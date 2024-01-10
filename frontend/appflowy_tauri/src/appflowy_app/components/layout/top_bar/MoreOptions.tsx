import React from 'react';
import FontSizeConfig from '$app/components/layout/top_bar/FontSizeConfig';
import { useMoreOptionsConfig } from '$app/components/layout/top_bar/MoreOptions.hooks';

function MoreOptions() {
  const { showStyleOptions } = useMoreOptionsConfig();

  return <div className={'flex w-[220px] flex-col'}>{showStyleOptions && <FontSizeConfig />}</div>;
}

export default MoreOptions;
