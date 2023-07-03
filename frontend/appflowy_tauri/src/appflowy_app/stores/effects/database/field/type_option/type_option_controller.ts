import { FieldPB, FieldType, TypeOptionPB } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { FieldBackendService } from '../field_bd_svc';
import { Log } from '$app/utils/log';
import { None, Option, Some } from 'ts-results';
import { FieldInfo } from '../field_controller';
import { TypeOptionBackendService } from './type_option_bd_svc';

export class TypeOptionController {
  private fieldNotifier = new ChangeNotifier<FieldPB>();
  private typeOptionData: Option<TypeOptionPB>;
  private fieldBackendSvc?: FieldBackendService;
  private typeOptionBackendSvc: TypeOptionBackendService;

  // Must call [initialize] if the passed-in fieldInfo is None
  constructor(
    public readonly viewId: string,
    private readonly initialFieldInfo: Option<FieldInfo> = None,
    private readonly defaultFieldType: FieldType = FieldType.RichText
  ) {
    this.typeOptionData = None;
    this.typeOptionBackendSvc = new TypeOptionBackendService(viewId);
  }

  // It will create a new field for the defaultFieldType if the [initialFieldInfo] is None.
  // Otherwise, it will get the type option of the [initialFieldInfo]
  initialize = async () => {
    if (this.initialFieldInfo.none) {
      await this.createTypeOption(this.defaultFieldType);
    } else {
      await this.getTypeOption();
    }
  };

  get fieldId(): string {
    return this.getFieldInfo().field.id;
  }

  get fieldType(): FieldType {
    return this.getFieldInfo().field.field_type;
  }

  getFieldInfo = (): FieldInfo => {
    if (this.typeOptionData.none) {
      if (this.initialFieldInfo.some) {
        return this.initialFieldInfo.val;
      } else {
        throw Error('Unexpected empty type option data. Should call initialize first');
      }
    }
    return new FieldInfo(this.typeOptionData.val.field);
  };

  switchToField = async (fieldType: FieldType) => {
    const result = await this.typeOptionBackendSvc.updateTypeOptionType(this.fieldId, fieldType);
    if (result.ok) {
      const getResult = await this.typeOptionBackendSvc.getTypeOption(this.fieldId, fieldType);
      if (getResult.ok) {
        this.updateTypeOptionData(getResult.val);
      }
      return getResult;
    }
    return result;
  };

  setFieldName = async (name: string) => {
    if (this.typeOptionData.some) {
      this.typeOptionData.val.field.name = name;
      void this.fieldBackendSvc?.updateField({ name: name });
      this.fieldNotifier.notify(this.typeOptionData.val.field);
    } else {
      throw Error('Unexpected empty type option data. Should call initialize first');
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

  saveTypeOption = async (data: Uint8Array) => {
    if (this.typeOptionData.some) {
      this.typeOptionData.val.type_option_data = data;
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
  getTypeOption = async () => {
    return this.typeOptionBackendSvc.getTypeOption(this.fieldId, this.fieldType).then((result) => {
      if (result.ok) {
        this.updateTypeOptionData(result.val);
      }
      return result;
    });
  };

  private createTypeOption = (fieldType: FieldType) => {
    return this.typeOptionBackendSvc.createTypeOption(fieldType).then((result) => {
      if (result.ok) {
        this.updateTypeOptionData(result.val);
      }
      return result;
    });
  };

  private updateTypeOptionData = (typeOptionData: TypeOptionPB) => {
    this.typeOptionData = Some(typeOptionData);
    this.fieldBackendSvc = new FieldBackendService(this.viewId, typeOptionData.field.id);
    this.fieldNotifier.notify(typeOptionData.field);
  };
}
