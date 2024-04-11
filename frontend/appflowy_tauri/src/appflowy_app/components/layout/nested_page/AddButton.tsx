import React, { useCallback, useMemo } from 'react';
import { ReactComponent as AddSvg } from '$app/assets/add.svg';
import { useTranslation } from 'react-i18next';
import { ReactComponent as DocumentSvg } from '$app/assets/document.svg';
import { ReactComponent as GridSvg } from '$app/assets/grid.svg';
import { ViewLayoutPB } from '@/services/backend';
import OperationMenu from '$app/components/layout/nested_page/OperationMenu';

function AddButton({
  isHovering,
  setHovering,
  onAddPage,
}: {
  isHovering: boolean;
  setHovering: (hovering: boolean) => void;
  onAddPage: (layout: ViewLayoutPB) => void;
}) {
  const { t } = useTranslation();

  const onConfirm = useCallback(
    (key: string) => {
      switch (key) {
        case 'document':
          onAddPage(ViewLayoutPB.Document);
          break;
        case 'grid':
          onAddPage(ViewLayoutPB.Grid);
          break;
        default:
          break;
      }
    },
    [onAddPage]
  );

  const options = useMemo(
    () => [
      {
        key: 'document',
        title: t('document.menuName'),
        icon: <DocumentSvg className={'h-4 w-4'} />,
      },
      {
        key: 'grid',
        title: t('grid.menuName'),
        icon: <GridSvg className={'h-4 w-4'} />,
      },
    ],
    [t]
  );

  return (
    <OperationMenu
      tooltip={t('menuAppHeader.addPageTooltip')}
      isHovering={isHovering}
      onConfirm={onConfirm}
      setHovering={setHovering}
      options={options}
    >
      <AddSvg />
    </OperationMenu>
  );
}

export default AddButton;
