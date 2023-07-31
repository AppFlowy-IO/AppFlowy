import { DateCellDataPB, FieldType, SelectOptionCellDataPB, URLCellDataPB } from '@/services/backend';
import { CellIdentifier } from './cell_bd_svc';
import { CellController } from './cell_controller';
import {
  CellDataLoader,
  DateCellDataParser,
  SelectOptionCellDataParser,
  StringCellDataParser,
  URLCellDataParser,
} from './data_parser';
import { CellCache } from './cell_cache';
import { FieldController } from '../field/field_controller';
import { DateCellDataPersistence, TextCellDataPersistence } from './data_persistence';

export type TextCellController = CellController<string, string>;

export type CheckboxCellController = CellController<string, string>;

export type NumberCellController = CellController<string, string>;

export type SelectOptionCellController = CellController<SelectOptionCellDataPB, string>;

export type DateCellController = CellController<DateCellDataPB, CalendarData>;

export class CalendarData {
  constructor(public readonly date: Date, public readonly includeTime: boolean, public readonly time?: string) {}
}

export type URLCellController = CellController<URLCellDataPB, string>;

export class CellControllerBuilder {
  constructor(
    public readonly cellIdentifier: CellIdentifier,
    public readonly cellCache: CellCache,
    public readonly fieldController: FieldController
  ) {}

  ///
  build = () => {
    switch (this.cellIdentifier.fieldType) {
      case FieldType.Checkbox:
        return this.makeCheckboxCellController();
      case FieldType.RichText:
        return this.makeTextCellController();
      case FieldType.Number:
        return this.makeNumberCellController();
      case FieldType.DateTime:
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return this.makeDateCellController();
      case FieldType.URL:
        return this.makeURLCellController();
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
      case FieldType.Checklist:
        return this.makeSelectOptionCellController();
    }
  };

  makeSelectOptionCellController = (): SelectOptionCellController => {
    const loader = new CellDataLoader(this.cellIdentifier, new SelectOptionCellDataParser(), true);
    const persistence = new TextCellDataPersistence(this.cellIdentifier);

    return new CellController<SelectOptionCellDataPB, string>(this.cellIdentifier, this.cellCache, loader, persistence);
  };

  makeURLCellController = (): URLCellController => {
    const loader = new CellDataLoader(this.cellIdentifier, new URLCellDataParser());
    const persistence = new TextCellDataPersistence(this.cellIdentifier);

    return new CellController<URLCellDataPB, string>(this.cellIdentifier, this.cellCache, loader, persistence);
  };

  makeDateCellController = (): DateCellController => {
    const loader = new CellDataLoader(this.cellIdentifier, new DateCellDataParser(), true);
    const persistence = new DateCellDataPersistence(this.cellIdentifier);

    return new CellController<DateCellDataPB, CalendarData>(this.cellIdentifier, this.cellCache, loader, persistence);
  };

  makeNumberCellController = (): NumberCellController => {
    const loader = new CellDataLoader(this.cellIdentifier, new StringCellDataParser(), true);
    const persistence = new TextCellDataPersistence(this.cellIdentifier);

    return new CellController<string, string>(this.cellIdentifier, this.cellCache, loader, persistence);
  };

  makeTextCellController = (): TextCellController => {
    const loader = new CellDataLoader(this.cellIdentifier, new StringCellDataParser());
    const persistence = new TextCellDataPersistence(this.cellIdentifier);

    return new CellController<string, string>(this.cellIdentifier, this.cellCache, loader, persistence);
  };

  makeCheckboxCellController = (): CheckboxCellController => {
    const loader = new CellDataLoader(this.cellIdentifier, new StringCellDataParser());
    const persistence = new TextCellDataPersistence(this.cellIdentifier);

    return new CellController<string, string>(this.cellIdentifier, this.cellCache, loader, persistence);
  };
}
