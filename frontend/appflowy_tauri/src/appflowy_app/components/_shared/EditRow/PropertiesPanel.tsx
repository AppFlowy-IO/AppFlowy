import { DropDownShowSvg } from '$app/components/_shared/svg/DropDownShowSvg';
import { useEffect, useState } from 'react';
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
}: {
  viewId: string;
  controller: DatabaseController;
  rowInfo: RowInfo;
  onDeletePropertyClick: (fieldId: string) => void;
}) => {
  const { cells } = useRow(viewId, controller, rowInfo);
  const databaseStore = useAppSelector((state) => state.database);

  const [showAddedProperties, setShowAddedProperties] = useState(true);
  const [showBasicProperties, setShowBasicProperties] = useState(false);
  const [showAdvancedProperties, setShowAdvancedProperties] = useState(false);

  const [hoveredPropertyIndex, setHoveredPropertyIndex] = useState(-1);
  const [hiddenProperties, setHiddenProperties] = useState<boolean[]>([]);

  useEffect(() => {
    setHiddenProperties(cells.map(() => false));
  }, [cells]);

  const toggleHideProperty = (v: boolean, index: number) => {
    setHiddenProperties(hiddenProperties.map((h, i) => (i === index ? !v : h)));
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
                <Switch value={!hiddenProperties[cellIndex]} setValue={(v) => toggleHideProperty(v, cellIndex)}></Switch>
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
            {typesOrder.map((t, i) => (
              <button
                onClick={() => console.log('type clicked')}
                key={i}
                className={'flex cursor-pointer items-center gap-2 rounded-lg px-2 py-2 pr-8 hover:bg-main-secondary'}
              >
                <i className={'h-5 w-5'}>
                  <FieldTypeIcon fieldType={t}></FieldTypeIcon>
                </i>
                <span>
                  <FieldTypeName fieldType={t}></FieldTypeName>
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
