import { FieldType, SortConditionPB } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';
import { IDatabaseSort } from '$app_reducers/database/slice';
import { SortBackendService } from '$app/stores/effects/database/sort/sort_bd_svc';

export class SortController {
  sortService: SortBackendService;
  notifier: SortNotifier;

  constructor(public readonly viewId: string) {
    this.sortService = new SortBackendService(viewId);
    this.notifier = new SortNotifier();
  }

  initialize = async () => {
    await this.readSorts();
  };

  readSorts = async () => {
    const result = await this.sortService.getSorts();

    if (result.ok) {
      this.notifier.sorts = result.val;
    }
  };

  addSort = async (fieldId: string, fieldType: FieldType, sort: SortConditionPB) => {
    const id = await this.sortService.addSort(fieldId, fieldType, sort);

    await this.readSorts();
    return id;
  };

  updateSort = async (sortId: string, fieldId: string, fieldType: FieldType, sort: SortConditionPB) => {
    const result = await this.sortService.updateSort(sortId, fieldId, fieldType, sort);

    if (result.ok) {
      await this.readSorts();
    }
  };

  removeSort = async (fieldId: string, fieldType: FieldType, sortId: string) => {
    const result = await this.sortService.removeSort(fieldId, fieldType, sortId);

    if (result.ok) {
      await this.readSorts();
    }
  };

  subscribe = (callbacks: { onSortChanged?: (sorts: IDatabaseSort[]) => void }) => {
    if (callbacks.onSortChanged) {
      this.notifier.observer?.subscribe(callbacks.onSortChanged);
    }
  };

  dispose = () => {
    this.notifier.unsubscribe();
  };
}

class SortNotifier extends ChangeNotifier<IDatabaseSort[]> {
  private _sorts: IDatabaseSort[] = [];

  get sorts(): IDatabaseSort[] {
    return this._sorts;
  }

  set sorts(value: IDatabaseSort[]) {
    this._sorts = value;
    this.notify(value);
  }
}
