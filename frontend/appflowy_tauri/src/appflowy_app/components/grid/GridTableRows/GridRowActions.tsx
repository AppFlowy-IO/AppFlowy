import { useRef } from 'react';
import useOutsideClick from '../../_shared/useOutsideClick';
import AddSvg from '../../_shared/svg/AddSvg';
import { CopySvg } from '../../_shared/svg/CopySvg';
import { TrashSvg } from '../../_shared/svg/TrashSvg';
import { ShareSvg } from '../../_shared/svg/ShareSvg';
import { DatabaseController } from '@/appflowy_app/stores/effects/database/database_controller';
import { useGridRowActions } from './GridRowActions.hooks';
import { IPopupItem, PopupSelect } from '$app/components/_shared/PopupSelect';

export const GridRowActions = ({
  onOutsideClick,
  controller,
  rowId,
}: {
  onOutsideClick: () => void;
  controller: DatabaseController;
  rowId: string;
}) => {
  const ref = useRef<HTMLDivElement>(null);

  useOutsideClick(ref, onOutsideClick);

  const { deleteRow, duplicateRow, insertRowAfter } = useGridRowActions(controller);

  const items: IPopupItem[] = [
    {
      title: 'Insert Record',
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <AddSvg />
        </i>
      ),
      onClick: () => insertRowAfter(rowId),
    },
    {
      title: 'Copy Link',
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <ShareSvg />
        </i>
      ),
      onClick: () => {
        console.log('copy link');
      },
    },
    {
      title: 'Duplicate',
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <CopySvg />
        </i>
      ),
      onClick: () => duplicateRow(rowId),
    },
    {
      title: 'Delete',
      icon: (
        <i className={'h-[16px] w-[16px] text-black'}>
          <TrashSvg />
        </i>
      ),
      onClick: () => deleteRow(rowId),
    },
  ];

  return <PopupSelect items={items} className={'absolute left-0'} onOutsideClick={onOutsideClick} />;
};
