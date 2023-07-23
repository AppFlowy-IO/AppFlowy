import { FilterBackendService } from '$app/stores/effects/database/filter/filter_bd_svc';
import { CheckboxFilterPB, FieldType, FilterPB, SelectOptionFilterPB, TextFilterPB } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';

export class FilterController {
  filterService: FilterBackendService;
  notifier: FilterNotifier;

  constructor(public readonly viewId: string) {
    this.filterService = new FilterBackendService(viewId);
    this.notifier = new FilterNotifier();
  }

  readFilters = async () => {
    const result = await this.filterService.getFilters();

    if (result.ok) {
      this.notifier.filters = result.val;
    }
  };

  addFilter = async (
    fieldId: string,
    fieldType: FieldType,
    filter: TextFilterPB | SelectOptionFilterPB | CheckboxFilterPB
  ) => {
    const result = await this.filterService.addFilter(fieldId, fieldType, filter);

    if (result.ok) {
      await this.readFilters();
    }
  };

  removeFilter = async (fieldId: string, fieldType: FieldType, filterId: string) => {
    const result = await this.filterService.removeFilter(fieldId, fieldType, filterId);

    if (result.ok) {
      await this.readFilters();
    }
  };

  subscribe = (callbacks: { onFiltersChanged?: (filters: FilterPB[]) => void }) => {
    if (callbacks.onFiltersChanged) {
      this.notifier.observer?.subscribe(callbacks.onFiltersChanged);
    }
  };

  dispose = () => {
    this.notifier.unsubscribe();
  };
}

class FilterNotifier extends ChangeNotifier<FilterPB[]> {
  private _filters: FilterPB[] = [];

  get filters(): FilterPB[] {
    return this._filters;
  }

  set filters(value: FilterPB[]) {
    this._filters = value;
    this.notify(value);
  }
}
