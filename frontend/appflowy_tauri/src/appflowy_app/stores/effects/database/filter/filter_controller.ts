import { FilterBackendService, FilterParsed } from '$app/stores/effects/database/filter/filter_bd_svc';
import { CheckboxFilterPB, FieldType, SelectOptionFilterPB, TextFilterPB } from '@/services/backend';
import { ChangeNotifier } from '$app/utils/change_notifier';

export class FilterController {
  filterService: FilterBackendService;
  notifier: FilterNotifier;

  constructor(public readonly viewId: string) {
    this.filterService = new FilterBackendService(viewId);
    this.notifier = new FilterNotifier();
  }

  initialize = async () => {
    await this.readFilters();
  };

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
    const id = await this.filterService.addFilter(fieldId, fieldType, filter);

    await this.readFilters();
    return id;
  };

  updateFilter = async (
    filterId: string,
    fieldId: string,
    fieldType: FieldType,
    filter: TextFilterPB | SelectOptionFilterPB | CheckboxFilterPB
  ) => {
    const result = await this.filterService.updateFilter(filterId, fieldId, fieldType, filter);

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

  subscribe = (callbacks: { onFiltersChanged?: (filters: FilterParsed[]) => void }) => {
    if (callbacks.onFiltersChanged) {
      this.notifier.observer?.subscribe(callbacks.onFiltersChanged);
    }
  };

  dispose = () => {
    this.notifier.unsubscribe();
  };
}

class FilterNotifier extends ChangeNotifier<FilterParsed[]> {
  private _filters: FilterParsed[] = [];

  get filters(): FilterParsed[] {
    return this._filters;
  }

  set filters(value: FilterParsed[]) {
    this._filters = value;
    this.notify(value);
  }
}
