import { FieldPB, FieldType } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FieldBackendService } from '../field_bd_svc';
import { Log } from '$app/utils/log';
import { None, Option, Some } from 'ts-results';
import { FieldInfo } from '../field_controller';
import { TypeOptionBackendService } from './type_option_bd_svc';

export class TypeOptionController {
  private fieldNotifier = new ChangeNotifier<FieldPB>();
  private field: Option<FieldPB>;
  private fieldBackendSvc?: FieldBackendService;
  private typeOptionBackendSvc: TypeOptionBackendService;

  // Must call [initialize] if the passed-in fieldInfo is None
  constructor(
    public readonly viewId: string,
    private readonly initialFieldInfo: Option<FieldInfo> = None,
    private readonly defaultFieldType: FieldType = FieldType.RichText
  ) {
    if (initialFieldInfo.none) {
      this.field = None;
    } else {
      this.field = Some(initialFieldInfo.val.field);    
      this.fieldBackendSvc = new FieldBackendService(this.viewId, initialFieldInfo.val.field.id);
    }

    this.typeOptionBackendSvc = new TypeOptionBackendService(viewId);
  }

  // It will create a new field for the defaultFieldType if the [initialFieldInfo] is None.
  // Otherwise, it will get the type option of the [initialFieldInfo]
  initialize = async () => {
    if (this.initialFieldInfo.none) {
      await this.createTypeOption(this.defaultFieldType);
    }
  };

  get fieldId(): string {
    return this.getFieldInfo().field.id;
  }

  get fieldType(): FieldType {
    return this.getFieldInfo().field.field_type;
  }

  getFieldInfo = (): FieldInfo => {
    if (this.field.none) {
      if (this.initialFieldInfo.some) {
        return this.initialFieldInfo.val;
      } else {
        throw Error('Unexpected empty type option data. Should call initialize first');
      }
    }

    return new FieldInfo(this.field.val);
  };

  switchToField = async (fieldType: FieldType) => {
    if (this.field.some) {
      this.field.val.field_type = fieldType;
      await this.typeOptionBackendSvc.updateTypeOptionType(this.fieldId, fieldType).then((result) => {
        if (result.err) {
          Log.error(result.val);
        }
      });
      this.fieldNotifier.notify(this.field.val);
    } else {
      throw Error('Unexpected empty type option data. Should call initialize first');
    }
  };

  setFieldName = async (name: string) => {
    if (this.field.some) {
      this.field.val.name = name;
      void this.fieldBackendSvc?.updateField({ name: name });
      this.fieldNotifier.notify(this.field.val);
    } 
  };

  hideField = async () => {
    if (this.fieldBackendSvc) {
      void this.fieldBackendSvc.updateField({ visibility: false });
    } else {
      throw Error('Unexpected empty field backend service');
    }
  };

  showField = async () => {
    if (this.fieldBackendSvc) {
      void this.fieldBackendSvc.updateField({ visibility: true });
    } else {
      throw Error('Unexpected empty field backend service');
    }
  };

  changeWidth = async (width: number) => {
    if (this.fieldBackendSvc) {
      void this.fieldBackendSvc.updateField({ width: width });
    } else {
      throw Error('Unexpected empty field backend service');
    }
  };

  saveTypeOption = async (data: Uint8Array) => {
    if (this.field.some) {
      this.field.val.type_option_data = data;
      await this.fieldBackendSvc?.updateTypeOption(data).then((result) => {
        if (result.err) {
          Log.error(result.val);
        }
      });
    } else {
      throw Error('Unexpected empty type option data. Should call initialize first');
    }
  };

  deleteField = async () => {
    if (this.fieldBackendSvc === undefined) {
      Log.error('Unexpected empty field backend service');
    }

    return this.fieldBackendSvc?.deleteField();
  };

  duplicateField = async () => {
    if (this.fieldBackendSvc === undefined) {
      Log.error('Unexpected empty field backend service');
    }

    return this.fieldBackendSvc?.duplicateField();
  };

  // Returns the type option for specific field with specific fieldType
  getTypeOption = () => {
    if (this.field.some) {
      return this.field.val.type_option_data;
    } else {
      throw Error('Unexpected empty type option data. Should call initialize first');
    }
  };

  private createTypeOption = async (fieldType: FieldType) => {
    const result = await this.typeOptionBackendSvc.createTypeOption(fieldType);

    if (result.ok) {
      this.updateField(result.val);
    }

    return result;
  };

  private updateField = (field: FieldPB) => {
    this.field = Some(field);    
    this.fieldBackendSvc = new FieldBackendService(this.viewId, field.id);
    this.fieldNotifier.notify(field);
  };
}
