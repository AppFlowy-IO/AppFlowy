import { FormEventHandler, useCallback, useEffect, useMemo, useState } from 'react';
import { t } from 'i18next';
import { PageController } from '$app/stores/effects/workspace/page/page_controller';
import { useViewId } from './database.hooks';

export const DatabaseHeader = () => {
  const viewId = useViewId();
  const [ title, setTitle ] = useState('');

  const controller = useMemo(() => new PageController(viewId), [ viewId ]);

  useEffect(() => {
    void controller.getPage().then(page => {
      setTitle(page.name);
    });

    void controller.subscribe({
      onPageChanged: (page) => {
        setTitle(page.name);
      },
    });

    return () => {
      void controller.unsubscribe();
    };
  }, [ controller ]);

  const handleInput = useCallback<FormEventHandler>((event) => {
    const newTitle = (event.target as HTMLInputElement).value;

    void controller.updatePage({
      id: viewId,
      name: newTitle,
    });
  }, [ viewId, controller ]);

  return (
    <div className="px-16 pt-8 mb-6">
      <input
        className="text-3xl font-semibold"
        value={title}
        placeholder={t('grid.title.placeholder')}
        onInput={handleInput}
      />
    </div>
  );
};
