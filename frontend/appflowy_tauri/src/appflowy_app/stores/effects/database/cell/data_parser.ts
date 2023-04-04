import utf8 from 'utf8';
import { CellBackendService, CellIdentifier } from './cell_bd_svc';
import { SelectOptionCellDataPB, URLCellDataPB, DateCellDataPB } from '@/services/backend';
import { Err, None, Ok, Option, Some } from 'ts-results';
import { Log } from '$app/utils/log';

abstract class CellDataParser<T> {
  abstract parserData(data: Uint8Array): Option<T>;
}

class CellDataLoader<T> {
  private service = new CellBackendService();

  constructor(
    readonly cellId: CellIdentifier,
    readonly parser: CellDataParser<T>,
    public readonly reloadOnFieldChanged: boolean = false
  ) {}

  loadData = async () => {
    const result = await this.service.getCell(this.cellId);
    if (result.ok) {
      return Ok(this.parser.parserData(result.val.data));
    } else {
      Log.error(result.err);
      return Err(result.err);
    }
  };
}

export const utf8Decoder = new TextDecoder('utf-8');
export const utf8Encoder = new TextEncoder();

class StringCellDataParser extends CellDataParser<string> {
  parserData(data: Uint8Array): Option<string> {
    return Some(utf8Decoder.decode(data));
  }
}

class DateCellDataParser extends CellDataParser<DateCellDataPB> {
  parserData(data: Uint8Array): Option<DateCellDataPB> {
    return Some(DateCellDataPB.deserializeBinary(data));
  }
}

class SelectOptionCellDataParser extends CellDataParser<SelectOptionCellDataPB> {
  parserData(data: Uint8Array): Option<SelectOptionCellDataPB> {
    if (data.length === 0) {
      return None;
    }
    return Some(SelectOptionCellDataPB.deserializeBinary(data));
  }
}

class URLCellDataParser extends CellDataParser<URLCellDataPB> {
  parserData(data: Uint8Array): Option<URLCellDataPB> {
    if (data.length === 0) {
      return None;
    }
    return Some(URLCellDataPB.deserializeBinary(data));
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
