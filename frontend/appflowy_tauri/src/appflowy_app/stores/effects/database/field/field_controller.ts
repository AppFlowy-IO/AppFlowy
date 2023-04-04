import { Log } from '$app/utils/log';
import { DatabaseBackendService } from '../database_bd_svc';
import { DatabaseFieldChangesetObserver } from './field_observer';
import { FieldIdPB, FieldPB, IndexFieldPB } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';

export class FieldController {
  private backendService: DatabaseBackendService;
  private fieldChangesetObserver: DatabaseFieldChangesetObserver;
  private numOfFieldsNotifier = new NumOfFieldsNotifier([]);

  constructor(public readonly viewId: string) {
    this.backendService = new DatabaseBackendService(viewId);
    this.fieldChangesetObserver = new DatabaseFieldChangesetObserver(viewId);
  }

  dispose = async () => {
    this.numOfFieldsNotifier.unsubscribe();
    await this.fieldChangesetObserver.unsubscribe();
  };

  get fieldInfos(): readonly FieldInfo[] {
    return this.numOfFieldsNotifier.fieldInfos;
  }

  getField = (fieldId: string): FieldInfo | undefined => {
    return this.numOfFieldsNotifier.fieldInfos.find((element) => element.field.id === fieldId);
  };

  loadFields = async (fieldIds: FieldIdPB[]) => {
    const result = await this.backendService.getFields(fieldIds);
    if (result.ok) {
      this.numOfFieldsNotifier.fieldInfos = result.val.map((field) => new FieldInfo(field));
    } else {
      Log.error(result.val);
    }
  };

  subscribe = (callbacks: { onNumOfFieldsChanged?: (fieldInfos: readonly FieldInfo[]) => void }) => {
    this.numOfFieldsNotifier.observer.subscribe((fieldInfos) => {
      callbacks.onNumOfFieldsChanged?.(fieldInfos);
    });
  };

  initialize = async () => {
    await this.fieldChangesetObserver.subscribe({
      onFieldsChanged: (result) => {
        if (result.ok) {
          const changeset = result.val;
          this._deleteFields(changeset.deleted_fields);
          this._insertFields(changeset.inserted_fields);
          this._updateFields(changeset.updated_fields);
        } else {
          Log.error(result.val);
        }
      },
    });
  };

  private _deleteFields = (deletedFields: FieldIdPB[]) => {
    if (deletedFields.length === 0) {
      return;
    }

    const deletedFieldIds = deletedFields.map((field) => field.field_id);
    const predicate = (element: FieldInfo): boolean => {
      return !deletedFieldIds.includes(element.field.id);
    };
    this.numOfFieldsNotifier.fieldInfos = [...this.fieldInfos].filter(predicate);
  };

  private _insertFields = (insertedFields: IndexFieldPB[]) => {
    if (insertedFields.length === 0) {
      return;
    }
    const newFieldInfos = [...this.fieldInfos];
    insertedFields.forEach((insertedField) => {
      const fieldInfo = new FieldInfo(insertedField.field);
      if (newFieldInfos.length > insertedField.index) {
        newFieldInfos.splice(insertedField.index, 0, fieldInfo);
      } else {
        newFieldInfos.push(fieldInfo);
      }
    });
    this.numOfFieldsNotifier.fieldInfos = newFieldInfos;
  };

  private _updateFields = (updatedFields: FieldPB[]) => {
    if (updatedFields.length === 0) {
      return;
    }

    const newFieldInfos = [...this.fieldInfos];
    updatedFields.forEach((updatedField) => {
      const index = newFieldInfos.findIndex((fieldInfo) => {
        return fieldInfo.field.id === updatedField.id;
      });
      if (index !== -1) {
        newFieldInfos.splice(index, 1, new FieldInfo(updatedField));
      }
    });
    this.numOfFieldsNotifier.fieldInfos = newFieldInfos;
  };
}

class NumOfFieldsNotifier extends ChangeNotifier<FieldInfo[]> {
  constructor(private _fieldInfos: FieldInfo[]) {
    super();
  }

  set fieldInfos(newFieldInfos: FieldInfo[]) {
    if (this._fieldInfos !== newFieldInfos) {
      this._fieldInfos = newFieldInfos;
      this.notify(this._fieldInfos);
    }
  }

  /// Return a readonly list
  get fieldInfos(): FieldInfo[] {
    return this._fieldInfos;
  }
}

export class FieldInfo {
  constructor(public readonly field: FieldPB) {}
}
