import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import { useState } from 'react';
import { useRow } from '$app/components/_shared/database-hooks/useRow';
import { DatabaseController } from '$app/stores/effects/database/database_controller';
import { RowInfo } from '$app/stores/effects/database/row/row_cache';
import { FieldTypeIcon } from '$app/components/_shared/EditRow/FieldTypeIcon';
import { useAppSelector } from '$app/stores/store';
import { Switch } from '$app/components/_shared/Switch';
import { FieldType } from '@/services/backend';
import { FieldTypeName } from '$app/components/_shared/EditRow/FieldTypeName';
import { TrashSvg } from '$app/components/_shared/svg/TrashSvg';
import { MultiSelectTypeSvg } from '$app/components/_shared/svg/MultiSelectTypeSvg';
import { DocumentSvg } from '$app/components/_shared/svg/DocumentSvg';
import { SingleSelectTypeSvg } from '$app/components/_shared/svg/SingleSelectTypeSvg';
import { TypeOptionController } from '$app/stores/effects/database/field/type_option/type_option_controller';
import { Some } from 'ts-results';
import { useTranslation } from 'react-i18next';

const typesOrder: FieldType[] = [
  FieldType.RichText,
  FieldType.Number,
  FieldType.DateTime,
  FieldType.SingleSelect,
  FieldType.MultiSelect,
  FieldType.Checkbox,
  FieldType.URL,
  FieldType.Checklist,
];

export const PropertiesPanel = ({
  viewId,
  controller,
  rowInfo,
  onDeletePropertyClick,
  onNewColumnClick,
}: {
  viewId: string;
  controller: DatabaseController;
  rowInfo: RowInfo;
  onDeletePropertyClick: (fieldId: string) => void;
  onNewColumnClick: (initialFieldType: FieldType, name?: string) => Promise<void>;
}) => {
  const { cells } = useRow(viewId, controller, rowInfo);
  const databaseStore = useAppSelector((state) => state.database);
  const { t } = useTranslation();

  const [showAddedProperties, setShowAddedProperties] = useState(true);
  const [showBasicProperties, setShowBasicProperties] = useState(false);
  const [showAdvancedProperties, setShowAdvancedProperties] = useState(false);

  const [hoveredPropertyIndex, setHoveredPropertyIndex] = useState(-1);

  const toggleHideProperty = async (v: boolean, index: number) => {
    const fieldInfo = controller.fieldController.getField(cells[index].fieldId);
    if (fieldInfo) {
      const typeController = new TypeOptionController(viewId, Some(fieldInfo));
      await typeController.initialize();
      if (fieldInfo.field.visibility) {
        await typeController.hideField();
      } else {
        await typeController.showField();
      }
    }
  };

  const addSelectedFieldType = async (fieldType: FieldType) => {
    let name = 'New Field';
    switch (fieldType) {
      case FieldType.RichText:
        name = t('grid.field.textFieldName');
        break;
      case FieldType.Number:
        name = t('grid.field.numberFieldName');
        break;
      case FieldType.DateTime:
        name = t('grid.field.dateFieldName');
        break;
      case FieldType.SingleSelect:
        name = t('grid.field.singleSelectFieldName');
        break;
      case FieldType.MultiSelect:
        name = t('grid.field.multiSelectFieldName');
        break;
      case FieldType.Checklist:
        name = t('grid.field.checklistFieldName');
        break;
      case FieldType.URL:
        name = t('grid.field.urlFieldName');
        break;
      case FieldType.Checkbox:
        name = t('grid.field.checkboxFieldName');
        break;
    }

    await onNewColumnClick(fieldType, name);
  };

  return (
    <div className={'flex flex-col gap-2 overflow-auto py-12 px-4'}>
      <div
        onClick={() => setShowAddedProperties(!showAddedProperties)}
        className={'flex cursor-pointer items-center justify-between gap-8 rounded-lg px-2 py-2 hover:bg-shade-6'}
      >
        <div className={'text-sm'}>Added Properties</div>
        <i className={`h-5 w-5 transition-transform duration-500 ${showAddedProperties && 'rotate-180'}`}>
          <DropDownShowSvg></DropDownShowSvg>
        </i>
      </div>
      <div className={'flex flex-col text-xs'} onMouseLeave={() => setHoveredPropertyIndex(-1)}>
        {showAddedProperties &&
          cells.map((cell, cellIndex) => (
            <div
              key={cellIndex}
              onMouseEnter={() => setHoveredPropertyIndex(cellIndex)}
              className={
                'flex cursor-pointer items-center justify-between gap-4 rounded-lg px-2 py-1 hover:bg-main-secondary'
              }
            >
              <div className={'flex items-center gap-2 text-black'}>
                <div className={'flex h-5 w-5 flex-shrink-0 items-center justify-center'}>
                  <FieldTypeIcon fieldType={cell.cellIdentifier.fieldType}></FieldTypeIcon>
                </div>
                <span className={'overflow-hidden text-ellipsis whitespace-nowrap'}>
                  {databaseStore.fields[cell.cellIdentifier.fieldId]?.title ?? ''}
                </span>
              </div>
              <div className={'flex items-center'}>
                <i
                  onClick={() => onDeletePropertyClick(cell.cellIdentifier.fieldId)}
                  className={`h-[16px] w-[16px] text-black transition-opacity duration-300 ${
                    hoveredPropertyIndex === cellIndex ? 'opacity-100' : 'opacity-0'
                  }`}
                >
                  <TrashSvg></TrashSvg>
                </i>
                <Switch
                  value={!!databaseStore.fields[cell.cellIdentifier.fieldId]?.visible}
                  setValue={(v) => toggleHideProperty(v, cellIndex)}
                ></Switch>
              </div>
            </div>
          ))}
      </div>
      <div
        onClick={() => setShowBasicProperties(!showBasicProperties)}
        className={'flex cursor-pointer items-center justify-between gap-8 rounded-lg px-2 py-2 hover:bg-shade-6'}
      >
        <div className={'text-sm'}>Basic Properties</div>
        <i className={`h-5 w-5 transition-transform duration-500 ${showBasicProperties && 'rotate-180'}`}>
          <DropDownShowSvg></DropDownShowSvg>
        </i>
      </div>
      <div className={'flex flex-col gap-2 text-xs'}>
        {showBasicProperties && (
          <div className={'flex flex-col'}>
            {typesOrder.map((type, i) => (
              <button
                onClick={() => addSelectedFieldType(type)}
                key={i}
                className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 pr-8 hover:bg-main-secondary'}
              >
                <i className={'h-5 w-5'}>
                  <FieldTypeIcon fieldType={type}></FieldTypeIcon>
                </i>
                <span>
                  <FieldTypeName fieldType={type}></FieldTypeName>
                </span>
              </button>
            ))}
          </div>
        )}
      </div>
      <div
        onClick={() => setShowAdvancedProperties(!showAdvancedProperties)}
        className={'flex cursor-pointer items-center justify-between gap-8 rounded-lg px-2 py-2 hover:bg-shade-6'}
      >
        <div className={'text-sm'}>Advanced Properties</div>
        <i className={`h-5 w-5 transition-transform duration-500 ${showAdvancedProperties && 'rotate-180'}`}>
          <DropDownShowSvg></DropDownShowSvg>
        </i>
      </div>
      <div className={'flex flex-col gap-2 text-xs'}>
        {showAdvancedProperties && (
          <div className={'flex flex-col'}>
            <button
              className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 pr-8 hover:bg-main-secondary'}
            >
              <i className={'h-5 w-5'}>
                <MultiSelectTypeSvg></MultiSelectTypeSvg>
              </i>
              <span>Last edited time</span>
            </button>
            <button
              className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 pr-8 hover:bg-main-secondary'}
            >
              <i className={'h-5 w-5'}>
                <DocumentSvg></DocumentSvg>
              </i>
              <span>Document</span>
            </button>
            <button
              className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 pr-8 hover:bg-main-secondary'}
            >
              <i className={'h-5 w-5'}>
                <SingleSelectTypeSvg></SingleSelectTypeSvg>
              </i>
              <span>Relation to</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
