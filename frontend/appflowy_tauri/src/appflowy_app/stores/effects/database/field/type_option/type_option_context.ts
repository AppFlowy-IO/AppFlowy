import { None, Ok, Option, Result, Some } from 'ts-results';
import { TypeOptionController } from './type_option_controller';
import {
  CheckboxTypeOptionPB,
  ChecklistTypeOptionPB,
  DateTypeOptionPB,
  FlowyError,
  MultiSelectTypeOptionPB,
  NumberTypeOptionPB,
  SingleSelectTypeOptionPB,
  URLTypeOptionPB,
} from '@/services/backend';
import { utf8Decoder, utf8Encoder } from '../../cell/data_parser';
import { DatabaseFieldObserver } from '../field_observer';

abstract class TypeOptionSerde<T> {
  abstract deserialize(buffer: Uint8Array): T;

  abstract serialize(value: T): Uint8Array;
}

// RichText
export function makeRichTextTypeOptionContext(controller: TypeOptionController): RichTextTypeOptionContext {
  const parser = new RichTextTypeOptionSerde();
  return new TypeOptionContext<string>(parser, controller);
}

export type RichTextTypeOptionContext = TypeOptionContext<string>;

class RichTextTypeOptionSerde extends TypeOptionSerde<string> {
  deserialize(buffer: Uint8Array): string {
    return utf8Decoder.decode(buffer);
  }

  serialize(value: string): Uint8Array {
    return utf8Encoder.encode(value);
  }
}

// Number
export function makeNumberTypeOptionContext(controller: TypeOptionController): NumberTypeOptionContext {
  const parser = new NumberTypeOptionSerde();
  return new TypeOptionContext<NumberTypeOptionPB>(parser, controller);
}

export type NumberTypeOptionContext = TypeOptionContext<NumberTypeOptionPB>;

class NumberTypeOptionSerde extends TypeOptionSerde<NumberTypeOptionPB> {
  deserialize(buffer: Uint8Array): NumberTypeOptionPB {
    return NumberTypeOptionPB.deserializeBinary(buffer);
  }

  serialize(value: NumberTypeOptionPB): Uint8Array {
    return value.serializeBinary();
  }
}

// Checkbox
export function makeCheckboxTypeOptionContext(controller: TypeOptionController): CheckboxTypeOptionContext {
  const parser = new CheckboxTypeOptionSerde();
  return new TypeOptionContext<CheckboxTypeOptionPB>(parser, controller);
}

export type CheckboxTypeOptionContext = TypeOptionContext<CheckboxTypeOptionPB>;

class CheckboxTypeOptionSerde extends TypeOptionSerde<CheckboxTypeOptionPB> {
  deserialize(buffer: Uint8Array): CheckboxTypeOptionPB {
    return CheckboxTypeOptionPB.deserializeBinary(buffer);
  }

  serialize(value: CheckboxTypeOptionPB): Uint8Array {
    return value.serializeBinary();
  }
}

// URL
export function makeURLTypeOptionContext(controller: TypeOptionController): URLTypeOptionContext {
  const parser = new URLTypeOptionSerde();
  return new TypeOptionContext<URLTypeOptionPB>(parser, controller);
}

export type URLTypeOptionContext = TypeOptionContext<URLTypeOptionPB>;

class URLTypeOptionSerde extends TypeOptionSerde<URLTypeOptionPB> {
  deserialize(buffer: Uint8Array): URLTypeOptionPB {
    return URLTypeOptionPB.deserializeBinary(buffer);
  }

  serialize(value: URLTypeOptionPB): Uint8Array {
    return value.serializeBinary();
  }
}

// Date
export function makeDateTypeOptionContext(controller: TypeOptionController): DateTypeOptionContext {
  const parser = new DateTypeOptionSerde();
  return new TypeOptionContext<DateTypeOptionPB>(parser, controller);
}

export type DateTypeOptionContext = TypeOptionContext<DateTypeOptionPB>;

class DateTypeOptionSerde extends TypeOptionSerde<DateTypeOptionPB> {
  deserialize(buffer: Uint8Array): DateTypeOptionPB {
    return DateTypeOptionPB.deserializeBinary(buffer);
  }

  serialize(value: DateTypeOptionPB): Uint8Array {
    return value.serializeBinary();
  }
}

// SingleSelect
export function makeSingleSelectTypeOptionContext(controller: TypeOptionController): SingleSelectTypeOptionContext {
  const parser = new SingleSelectTypeOptionSerde();
  return new TypeOptionContext<SingleSelectTypeOptionPB>(parser, controller);
}

export type SingleSelectTypeOptionContext = TypeOptionContext<SingleSelectTypeOptionPB>;

class SingleSelectTypeOptionSerde extends TypeOptionSerde<SingleSelectTypeOptionPB> {
  deserialize(buffer: Uint8Array): SingleSelectTypeOptionPB {
    return SingleSelectTypeOptionPB.deserializeBinary(buffer);
  }

  serialize(value: SingleSelectTypeOptionPB): Uint8Array {
    return value.serializeBinary();
  }
}

// Multi-select
export function makeMultiSelectTypeOptionContext(controller: TypeOptionController): MultiSelectTypeOptionContext {
  const parser = new MultiSelectTypeOptionSerde();
  return new TypeOptionContext<MultiSelectTypeOptionPB>(parser, controller);
}

export type MultiSelectTypeOptionContext = TypeOptionContext<MultiSelectTypeOptionPB>;

class MultiSelectTypeOptionSerde extends TypeOptionSerde<MultiSelectTypeOptionPB> {
  deserialize(buffer: Uint8Array): MultiSelectTypeOptionPB {
    return MultiSelectTypeOptionPB.deserializeBinary(buffer);
  }

  serialize(value: MultiSelectTypeOptionPB): Uint8Array {
    return value.serializeBinary();
  }
}

// Checklist
export function makeChecklistTypeOptionContext(controller: TypeOptionController): ChecklistTypeOptionContext {
  const parser = new ChecklistTypeOptionSerde();
  return new TypeOptionContext<ChecklistTypeOptionPB>(parser, controller);
}

export type ChecklistTypeOptionContext = TypeOptionContext<ChecklistTypeOptionPB>;

class ChecklistTypeOptionSerde extends TypeOptionSerde<ChecklistTypeOptionPB> {
  deserialize(buffer: Uint8Array): ChecklistTypeOptionPB {
    return ChecklistTypeOptionPB.deserializeBinary(buffer);
  }

  serialize(value: ChecklistTypeOptionPB): Uint8Array {
    return value.serializeBinary();
  }
}

export class TypeOptionContext<T> {
  private typeOption: Option<T>;
  private fieldObserver: DatabaseFieldObserver;

  constructor(public readonly parser: TypeOptionSerde<T>, private readonly controller: TypeOptionController) {
    this.typeOption = None;
    this.fieldObserver = new DatabaseFieldObserver(controller.fieldId);

    void this.fieldObserver.subscribe({
      onFieldChanged: () => {
        void this.getTypeOption();
      },
    });
  }

  get viewId(): string {
    return this.controller.viewId;
  }

  getTypeOption = async (): Promise<Result<T, FlowyError>> => {
    const result = await this.controller.getTypeOption();
    if (result.ok) {
      const typeOption = this.parser.deserialize(result.val.type_option_data);
      this.typeOption = Some(typeOption);
      return Ok(typeOption);
    } else {
      return result;
    }
  };

  // Save the typeOption to disk
  setTypeOption = async (typeOption: T) => {
    await this.controller.saveTypeOption(this.parser.serialize(typeOption));
    this.typeOption = Some(typeOption);
  };

  dispose = async () => {
    await this.fieldObserver.unsubscribe();
  };
}
