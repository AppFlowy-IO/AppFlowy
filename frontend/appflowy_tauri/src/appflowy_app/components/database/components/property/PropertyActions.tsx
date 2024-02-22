import React, { RefObject, useCallback, useMemo, useState } from 'react';

import { ReactComponent as EditSvg } from '$app/assets/edit.svg';
import { ReactComponent as HideSvg } from '$app/assets/hide.svg';
import { ReactComponent as ShowSvg } from '$app/assets/eye_open.svg';

import { ReactComponent as CopySvg } from '$app/assets/copy.svg';
import { ReactComponent as DeleteSvg } from '$app/assets/delete.svg';
import { ReactComponent as LeftSvg } from '$app/assets/left.svg';
import { ReactComponent as RightSvg } from '$app/assets/right.svg';
import { useViewId } from '$app/hooks';
import { fieldService } from '$app/application/database';
import { OrderObjectPositionTypePB, FieldVisibility } from '@/services/backend';
import DeleteConfirmDialog from '$app/components/_shared/confirm_dialog/DeleteConfirmDialog';
import { useTranslation } from 'react-i18next';
import KeyboardNavigation, {
  KeyboardNavigationOption,
} from '$app/components/_shared/keyboard_navigation/KeyboardNavigation';
import { notify } from 'src/appflowy_app/components/_shared/notify';

export enum FieldAction {
  EditProperty,
  Hide,
  Show,
  Duplicate,
  Delete,
  InsertLeft,
  InsertRight,
}

const FieldActionSvgMap = {
  [FieldAction.EditProperty]: EditSvg,
  [FieldAction.Hide]: HideSvg,
  [FieldAction.Show]: ShowSvg,
  [FieldAction.Duplicate]: CopySvg,
  [FieldAction.Delete]: DeleteSvg,
  [FieldAction.InsertLeft]: LeftSvg,
  [FieldAction.InsertRight]: RightSvg,
};

const defaultActions: FieldAction[] = [
  FieldAction.EditProperty,
  FieldAction.InsertLeft,
  FieldAction.InsertRight,
  FieldAction.Hide,
  FieldAction.Duplicate,
  FieldAction.Delete,
];

// prevent default actions for primary fields
const primaryPreventDefaultActions = [FieldAction.Hide, FieldAction.Delete, FieldAction.Duplicate];

interface PropertyActionsProps {
  fieldId: string;
  actions?: FieldAction[];
  isPrimary?: boolean;
  inputRef?: RefObject<HTMLElement>;
  onClose?: () => void;
  onMenuItemClick?: (action: FieldAction, newFieldId?: string) => void;
}

function PropertyActions({
  onClose,
  inputRef,
  fieldId,
  onMenuItemClick,
  isPrimary,
  actions = defaultActions,
}: PropertyActionsProps) {
  const viewId = useViewId();
  const { t } = useTranslation();
  const [openConfirm, setOpenConfirm] = useState(false);
  const [focusMenu, setFocusMenu] = useState<boolean>(false);
  const menuTextMap = useMemo(
    () => ({
      [FieldAction.EditProperty]: t('grid.field.editProperty'),
      [FieldAction.Hide]: t('grid.field.hide'),
      [FieldAction.Show]: t('grid.field.show'),
      [FieldAction.Duplicate]: t('grid.field.duplicate'),
      [FieldAction.Delete]: t('grid.field.delete'),
      [FieldAction.InsertLeft]: t('grid.field.insertLeft'),
      [FieldAction.InsertRight]: t('grid.field.insertRight'),
    }),
    [t]
  );

  const handleOpenConfirm = () => {
    setOpenConfirm(true);
  };

  const handleMenuItemClick = async (action: FieldAction) => {
    const preventDefault = isPrimary && primaryPreventDefaultActions.includes(action);

    if (preventDefault) {
      return;
    }

    switch (action) {
      case FieldAction.EditProperty:
        break;
      case FieldAction.InsertLeft:
      case FieldAction.InsertRight: {
        const fieldPosition =
          action === FieldAction.InsertLeft ? OrderObjectPositionTypePB.Before : OrderObjectPositionTypePB.After;

        const field = await fieldService.createField({
          viewId,
          fieldPosition,
          targetFieldId: fieldId,
        });

        onMenuItemClick?.(action, field.id);
        return;
      }

      case FieldAction.Hide:
        await fieldService.updateFieldSetting(viewId, fieldId, {
          visibility: FieldVisibility.AlwaysHidden,
        });
        break;
      case FieldAction.Show:
        await fieldService.updateFieldSetting(viewId, fieldId, {
          visibility: FieldVisibility.AlwaysShown,
        });
        break;
      case FieldAction.Duplicate:
        await fieldService.duplicateField(viewId, fieldId);
        break;
      case FieldAction.Delete:
        handleOpenConfirm();
        return;
    }

    onMenuItemClick?.(action);
  };

  const renderActionContent = useCallback((item: { text: string; Icon: React.FC<React.SVGProps<SVGSVGElement>> }) => {
    const { Icon, text } = item;

    return (
      <div className='flex w-full items-center gap-2 px-1'>
        <Icon className={'h-4 w-4'} />
        <div className={'flex-1'}>{text}</div>
      </div>
    );
  }, []);

  const options: KeyboardNavigationOption<FieldAction>[] = useMemo(
    () =>
      [
        {
          key: FieldAction.EditProperty,
          content: renderActionContent({
            text: menuTextMap[FieldAction.EditProperty],
            Icon: FieldActionSvgMap[FieldAction.EditProperty],
          }),
          disabled: isPrimary && primaryPreventDefaultActions.includes(FieldAction.EditProperty),
        },
        {
          key: FieldAction.InsertLeft,
          content: renderActionContent({
            text: menuTextMap[FieldAction.InsertLeft],
            Icon: FieldActionSvgMap[FieldAction.InsertLeft],
          }),
          disabled: isPrimary && primaryPreventDefaultActions.includes(FieldAction.InsertLeft),
        },
        {
          key: FieldAction.InsertRight,
          content: renderActionContent({
            text: menuTextMap[FieldAction.InsertRight],
            Icon: FieldActionSvgMap[FieldAction.InsertRight],
          }),
          disabled: isPrimary && primaryPreventDefaultActions.includes(FieldAction.InsertRight),
        },
        {
          key: FieldAction.Hide,
          content: renderActionContent({
            text: menuTextMap[FieldAction.Hide],
            Icon: FieldActionSvgMap[FieldAction.Hide],
          }),
          disabled: isPrimary && primaryPreventDefaultActions.includes(FieldAction.Hide),
        },
        {
          key: FieldAction.Show,
          content: renderActionContent({
            text: menuTextMap[FieldAction.Show],
            Icon: FieldActionSvgMap[FieldAction.Show],
          }),
        },
        {
          key: FieldAction.Duplicate,
          content: renderActionContent({
            text: menuTextMap[FieldAction.Duplicate],
            Icon: FieldActionSvgMap[FieldAction.Duplicate],
          }),
          disabled: isPrimary && primaryPreventDefaultActions.includes(FieldAction.Duplicate),
        },
        {
          key: FieldAction.Delete,
          content: renderActionContent({
            text: menuTextMap[FieldAction.Delete],
            Icon: FieldActionSvgMap[FieldAction.Delete],
          }),
          disabled: isPrimary && primaryPreventDefaultActions.includes(FieldAction.Delete),
        },
      ].filter((option) => actions.includes(option.key)),
    [renderActionContent, menuTextMap, isPrimary, actions]
  );

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      const isTab = e.key === 'Tab';

      if (!focusMenu && (e.key === 'ArrowDown' || e.key === 'ArrowUp')) {
        e.stopPropagation();
        notify.clear();
        notify.info(`Press Tab to focus on the menu`);
        return;
      }

      if (isTab) {
        e.preventDefault();
        e.stopPropagation();
        if (focusMenu) {
          inputRef?.current?.focus();
          setFocusMenu(false);
        } else {
          inputRef?.current?.blur();
          setFocusMenu(true);
        }

        return;
      }
    },
    [focusMenu, inputRef]
  );

  return (
    <>
      <KeyboardNavigation
        disableFocus={!focusMenu}
        disableSelect={!focusMenu}
        onEscape={onClose}
        focusRef={inputRef}
        options={options}
        onFocus={() => {
          setFocusMenu(true);
        }}
        onBlur={() => {
          setFocusMenu(false);
        }}
        onKeyDown={handleKeyDown}
        onConfirm={handleMenuItemClick}
      />
      <DeleteConfirmDialog
        open={openConfirm}
        subtitle={''}
        title={t('grid.field.deleteFieldPromptMessage')}
        onOk={async () => {
          await fieldService.deleteField(viewId, fieldId);
        }}
        onClose={() => {
          setOpenConfirm(false);
          onClose?.();
        }}
      />
    </>
  );
}

export default PropertyActions;
