import { notify } from '@/components/_shared/notify';
import { TaskAltRounded } from '@mui/icons-material';
import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Checkbox,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  Typography,
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';

const MAX_DELETE = 50;
const IndexedDBCleaner = () => {
  const [databases, setDatabases] = useState<string[]>([]);
  const [selectedDbs, setSelectedDbs] = useState<string[]>([]);
  const [countdown, setCountdown] = useState(0);

  useEffect(() => {
    const fetchDatabases = async () => {
      const dbs = await window.indexedDB.databases();

      setDatabases(dbs.map(db => db.name || '').filter(Boolean));
    };

    void fetchDatabases();
  }, []);

  const handleToggle = (dbName: string) => {
    const currentIndex = selectedDbs.indexOf(dbName);
    const newChecked = [...selectedDbs];

    if (currentIndex === -1) {
      if (newChecked.length < MAX_DELETE) {
        newChecked.push(dbName);
      } else {
        notify.warning('You can select a maximum of 10 databases.');
        return;
      }
    } else {
      newChecked.splice(currentIndex, 1);
    }

    setSelectedDbs(newChecked);
  };

  const handleDelete = async () => {
    if (selectedDbs.length === 0) {
      notify.warning('Please select at least one database to delete.');
      return;
    }

    for (const dbName of selectedDbs) {
      indexedDB.deleteDatabase(dbName);
    }

    setDatabases(databases.filter(db => !selectedDbs.includes(db)));
    setSelectedDbs([]);
    notify.success('Selected databases deleted successfully.');

    setCountdown(15);

    const reduceCountdown = () => {
      setTimeout(() => {
        setCountdown(prev => {
          if (prev === 0) return 0;
          return prev - 1;
        });
        reduceCountdown();
      }, 1000);
    };

    reduceCountdown();

  };

  if (databases.length === 0) return null;
  return (
    <div className={'w-full max-h-[360px] appflowy-scroller overflow-x-hidden overflow-y-auto'}>

      <List sx={{ width: '100%' }}>
        {databases.map((dbName) => {
          const labelId = `checkbox-list-label-${dbName}`;

          return (
            <ListItem
              key={dbName}
              dense
              button
              onClick={() => handleToggle(dbName)}
            >
              <ListItemIcon>
                <Checkbox
                  edge="start"
                  checked={selectedDbs.indexOf(dbName) !== -1}
                  tabIndex={-1}
                  disableRipple
                  inputProps={{ 'aria-labelledby': labelId }}
                />
              </ListItemIcon>
              <ListItemText id={labelId} primary={dbName} />
            </ListItem>
          );
        })}
      </List>
      <Box
        className={'sticky bottom-0 p-2 bg-bg-body z-10'}
        sx={{ mt: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
      >
        <Typography variant="body2">
          Total: {databases.length}
        </Typography>
        <Typography variant="body2">
          Selected: {selectedDbs.length}/{MAX_DELETE}
        </Typography>
        <div className={'flex items-center gap-2'}>
          <Button
            startIcon={
              <TaskAltRounded />
            } variant="contained" onClick={() => setSelectedDbs(databases.slice(0, MAX_DELETE))}
          >
            Select All
          </Button>
          <Button
            variant="contained"
            color="error"
            startIcon={<DeleteIcon />}
            onClick={handleDelete}
            disabled={selectedDbs.length === 0 || countdown !== 0}
          >
            Delete Selected{countdown ? ` (${countdown}s)` : ''}
          </Button>
        </div>
      </Box>
    </div>
  );
};

export default IndexedDBCleaner;