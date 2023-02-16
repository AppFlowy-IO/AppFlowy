import utf8 from 'utf8';
import { CellBackendService, CellIdentifier } from './backend_service';
import { DateCellDataPB } from '../../../../../services/backend/models/flowy-database/date_type_option_entities';
import { SelectOptionCellDataPB } from '../../../../../services/backend/models/flowy-database/select_type_option';
import { URLCellDataPB } from '../../../../../services/backend/models/flowy-database/url_type_option_entities';
import { Err, Ok } from 'ts-results';
import { Log } from '../../../../utils/log';

abstract class CellDataParser<T> {
  abstract parserData(data: Uint8Array): T | undefined;
}

class CellDataLoader<T> {
  _service = new CellBackendService();

  constructor(
    readonly cellId: CellIdentifier,
    readonly parser: CellDataParser<T>,
    private reloadOnFieldChanged: boolean
  ) {}

  loadData = async () => {
    const result = await this._service.getCell(this.cellId);
    if (result.ok) {
      return Ok(this.parser.parserData(result.val.data));
    } else {
      Log.error(result.err);
      return Err(result.err);
    }
  };
}

class StringCellDataParser extends CellDataParser<string> {
  parserData(data: Uint8Array): string {
    return utf8.decode(data.toString());
  }
}

class DateCellDataParser extends CellDataParser<DateCellDataPB> {
  parserData(data: Uint8Array): DateCellDataPB {
    return DateCellDataPB.deserializeBinary(data);
  }
}

class SelectOptionCellDataParser extends CellDataParser<SelectOptionCellDataPB | undefined> {
  parserData(data: Uint8Array): SelectOptionCellDataPB | undefined {
    if (data.length === 0) {
      return undefined;
    }
    return SelectOptionCellDataPB.deserializeBinary(data);
  }
}

class URLCellDataParser extends CellDataParser<URLCellDataPB | undefined> {
  parserData(data: Uint8Array): URLCellDataPB | undefined {
    if (data.length === 0) {
      return undefined;
    }
    return URLCellDataPB.deserializeBinary(data);
  }
}

export {
  StringCellDataParser,
  DateCellDataParser,
  SelectOptionCellDataParser,
  URLCellDataParser,
  CellDataLoader,
  CellDataParser,
};
