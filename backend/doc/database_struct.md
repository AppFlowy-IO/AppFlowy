
# Table Struct

## Table: user_table

- `Name`: UserTable
- `Comment`: UserTable

### `Primary Key`

- `Columns`: id

### `Indexes[]`

| `Columns` | `Unique` |
| --------- | -------- |
| email     | `true`   |

### `Foreign Keys[]`

| `Columns` | `Ref Table` | `Ref Columns` | `Options` |
| --------- | ----------- | ------------- | --------- |


### `Columns[]`

| `Label`     | `Name`      | `Type`      | `Nullable` | `Default` | `Comment` |
| ----------- | ----------- | ----------- | ---------- | --------- | --------- |
| id          | id          | uuid        | `false`    |           |           |
| email       | email       | text        | `false`    |           |           |
| name        | name        | text        | `false`    |           |           |
| password    | password    | text        | `false`    |           |           |
| create_time | create_time | timestamptz | `false`    |           |           |


## Table: workspace_table

- `Name`: WorkspaceTable
- `Comment`: WorkspaceTable

### `Primary Key`

- `Columns`: id

### `Indexes[]`

| `Columns` | `Unique` |
| --------- | -------- |

### `Foreign Keys[]`

| `Columns` | `Ref Table` | `Ref Columns` | `Options` |
| --------- | ----------- | ------------- | --------- |
| user_id   | user_table  | id            |           |

### `Columns[]`

| `Label`       | `Name`        | `Type`      | `Nullable` | `Default` | `Comment` |
| ------------- | ------------- | ----------- | ---------- | --------- | --------- |
| id            | id            | uuid        | `false`    |           |           |
| user_id       | user_id       | text        | `false`    |           |           |
| name          | name          | text        | `false`    |           |           |
| description   | description   | text        | `false`    |           |           |
| create_time   | create_time   | timestamptz | `false`    |           |           |
| modified_time | modified_time | timestamptz | `false`    |           |           |


## Table: app_table

- `Name`: AppTable
- `Comment`: AppTable

### `Primary Key`

- `Columns`: id

### `Indexes[]`

| `Columns` | `Unique` |
| --------- | -------- |

### `Foreign Keys[]`

| `Columns`    | `Ref Table`     | `Ref Columns` | `Options` |
| ------------ | --------------- | ------------- | --------- |
| user_id      | user_table      | id            |           |
| workspace_id | workspace_table | id            |           |
| last_view_id | view_table      | id            |           |

### `Columns[]`

| `Label`       | `Name`        | `Type`      | `Nullable` | `Default` | `Comment` |
| ------------- | ------------- | ----------- | ---------- | --------- | --------- |
| id            | id            | uuid        | `false`    |           |           |
| user_id       | user_id       | text        | `false`    |           |           |
| workspace_id  | workspace_id  | text        | `false`    |           |           |
| last_view_id  | workspace_id  | text        | `false`    |           |           |
| name          | name          | text        | `false`    |           |           |
| description   | description   | text        | `false`    |           |           |
| color_style   | color_style   | text        | `false`    |           |           |
| is_trash      | is_trash      | bool        | `false`    | `false`   |           |
| create_time   | create_time   | timestamptz | `false`    |           |           |
| modified_time | modified_time | timestamptz | `false`    |           |           |


## Table: view_table

- `Name`: ViewTable
- `Comment`: ViewTable

### `Primary Key`

- `Columns`: id

### `Indexes[]`

| `Columns` | `Unique` |
| --------- | -------- |

### `Foreign Keys[]`

| `Columns`    | `Ref Table` | `Ref Columns` | `Options` |
| ------------ | ----------- | ------------- | --------- |
| user_id      | user_table  | id            |           |
| belong_to_id | app_table   | id            |           |

### `Columns[]`

| `Label`       | `Name`        | `Type`      | `Nullable` | `Default` | `Comment` |
| ------------- | ------------- | ----------- | ---------- | --------- | --------- |
| id            | id            | uuid        | `false`    |           |           |
| belong_to_id  | belong_to_id  | text        | `false`    |           |           |
| name          | name          | text        | `false`    |           |           |
| description   | description   | text        | `false`    |           |           |
| thumbnail     | thumbnail     | text        | `false`    |           |           |
| view_type     | view_type     | int         | `false`    |           |           |
| create_time   | create_time   | timestamptz | `false`    |           |           |
| modified_time | modified_time | timestamptz | `false`    |           |           |


## Table: doc_table

- `Name`: DocTable
- `Comment`: DocTable

### `Primary Key`

- `Columns`: id

### `Indexes[]`

| `Columns` | `Unique` |
| --------- | -------- |

### `Foreign Keys[]`

| `Columns` | `Ref Table` | `Ref Columns` | `Options` |
| --------- | ----------- | ------------- | --------- |
| rev_id    | doc_table   | id            |           |



### `Columns[]`

| `Label` | `Name` | `Type` | `Nullable` | `Default` | `Comment` |
| ------- | ------ | ------ | ---------- | --------- | --------- |
| id      | id     | uuid   | `false`    |           |           |
| rev_id  | rev_id | text   | `false`    |           |           |
| data    | data   | text   | `false`    |           |           |


## Table: trash_table

- `Name`: TrashTable
- `Comment`: TrashTable

### `Primary Key`

- `Columns`: id

### `Indexes[]`

| `Columns` | `Unique` |
| --------- | -------- |

### `Foreign Keys[]`

| `Columns` | `Ref Table` | `Ref Columns` | `Options` |
| --------- | ----------- | ------------- | --------- |
| user_id   | user_table  | id            |           |


### `Columns[]`

| `Label` | `Name`  | `Type` | `Nullable` | `Default` | `Comment` |
| ------- | ------- | ------ | ---------- | --------- | --------- |
| id      | id      | uuid   | `false`    |           |           |
| user_id | user_id | text   | `false`    |           |           |
| ty      | ty      | int4   | `false`    | 0         |           |

