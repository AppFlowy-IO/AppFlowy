import { SelectOption } from '../select-option';

export interface ChecklistCellData {
  selectedOptionIds?: string[];
  options?: SelectOption[];
  percentage: number;
}

export function parseChecklistData(data: string): ChecklistCellData | null {
  try {
    const { options, selected_option_ids } = JSON.parse(data);
    const percentage = selected_option_ids.length / options.length;

    return {
      percentage,
      options,
      selectedOptionIds: selected_option_ids,
    };
  } catch (e) {
    return null;
  }
}
