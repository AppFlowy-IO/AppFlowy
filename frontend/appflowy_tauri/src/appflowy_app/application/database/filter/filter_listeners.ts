import { Database, pbToFilter } from '$app/application/database';
import { FilterChangesetNotificationPB } from '@/services/backend';

export const didUpdateFilter = (database: Database, changeset: FilterChangesetNotificationPB) => {
  const filters = changeset.filters.items.map((pb) => pbToFilter(pb));

  database.filters = filters;
};
