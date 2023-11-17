import React from 'react';
import { Cell } from '$app/components/database/components';
import { Field } from '$app/components/database/application';
import { useTranslation } from 'react-i18next';

function PropertyValue(props: { rowId: string; field: Field }) {
  const { t } = useTranslation();

  return (
    <div className={'flex h-9 flex-1 items-center'}>
      <Cell placeholder={t('grid.row.textPlaceholder')} {...props} />
    </div>
  );
}

export default React.memo(PropertyValue);
