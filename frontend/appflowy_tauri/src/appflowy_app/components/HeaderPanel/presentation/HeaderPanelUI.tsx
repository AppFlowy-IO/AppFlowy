import { Breadcrumbs } from '../../Breadcrumbs/application/Breadcrumbs';
import { PageOptions } from '../../PageOptions/application/PageOptions';

export const HeaderPanelUI = () => {
  return (
    <div className={'flex items-center justify-between px-2 py-2'}>
      <Breadcrumbs></Breadcrumbs>
      <PageOptions></PageOptions>
    </div>
  );
};
