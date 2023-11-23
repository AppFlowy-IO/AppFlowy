import { Database, pbToFilter } from '$app/components/database/application';
import { FilterChangesetNotificationPB } from '@/services/backend';

const deleteFiltersFromChange = (database: Database, changeset: FilterChangesetNotificationPB) => {
  const deleteIds = changeset.delete_filters.map((pb) => pb.id);

  if (deleteIds.length) {
    database.filters = database.filters.filter((item) => !deleteIds.includes(item.id));
  }
};

const insertFiltersFromChange = (database: Database, changeset: FilterChangesetNotificationPB) => {
  changeset.insert_filters.forEach((pb) => {
    database.filters.push(pbToFilter(pb));
  });
};

const updateFiltersFromChange = (database: Database, changeset: FilterChangesetNotificationPB) => {
  changeset.update_filters.forEach((pb) => {
    const found = database.filters.find((item) => item.id === pb.filter_id);

    if (found) {
      const newFilter = pbToFilter(pb.filter);

      Object.assign(found, newFilter);
    }
  });
};

export const didUpdateFilter = (database: Database, changeset: FilterChangesetNotificationPB) => {
  deleteFiltersFromChange(database, changeset);
  insertFiltersFromChange(database, changeset);
  updateFiltersFromChange(database, changeset);
};
