import { SortChangesetNotificationPB } from '@/services/backend';
import { Database } from '../database';
import { pbToSort } from './sort_types';

const deleteSortsFromChange = (database: Database, changeset: SortChangesetNotificationPB) => {
  const deleteIds = changeset.delete_sorts.map(sort => sort.id);

  if (deleteIds.length) {
    database.sorts = database.sorts.filter(sort => !deleteIds.includes(sort.id));
  }
};

const insertSortsFromChange = (database: Database, changeset: SortChangesetNotificationPB) => {
  changeset.insert_sorts.forEach(sortPB => {
    database.sorts.push(pbToSort(sortPB.sort));
  });
};

const updateSortsFromChange = (database: Database, changeset: SortChangesetNotificationPB) => {
  changeset.update_sorts.forEach(sortPB => {
    const found = database.sorts.find(sort => sort.id === sortPB.id);

    if (found) {
      const newSort = pbToSort(sortPB);

      Object.assign(found, newSort);
    }
  });
};

export const didUpdateSort = (database: Database, changeset: SortChangesetNotificationPB) => {
  deleteSortsFromChange(database, changeset);
  insertSortsFromChange(database, changeset);
  updateSortsFromChange(database, changeset);
};
