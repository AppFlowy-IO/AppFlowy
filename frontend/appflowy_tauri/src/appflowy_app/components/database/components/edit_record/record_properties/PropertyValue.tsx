import React, { useEffect, useRef, useState } from 'react';
import { Cell } from '$app/components/database/components';
import { Field } from '$app/components/database/application';
import { useTranslation } from 'react-i18next';

function PropertyValue(props: { rowId: string; field: Field }) {
  const { t } = useTranslation();
  const ref = useRef<HTMLDivElement>(null);
  const [width, setWidth] = useState(props.field.width);

  useEffect(() => {
    const el = ref.current;

    if (!el) return;
    const width = el.getBoundingClientRect().width;

    setWidth(width);
  }, []);
  return (
    <div ref={ref} className={'flex min-h-[36px] flex-1 items-center'}>
      <Cell
        placeholder={t('grid.row.textPlaceholder')}
        {...props}
        field={{
          ...props.field,
          width,
        }}
      />
    </div>
  );
}

export default React.memo(PropertyValue);
