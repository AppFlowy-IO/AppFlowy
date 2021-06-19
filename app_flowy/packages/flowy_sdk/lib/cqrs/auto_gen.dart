

/// Auto gen code from rust ast, do not edit
part of 'cqrs.dart';
class WorkspaceCreateRequest {
    WorkspaceCreation body;
    WorkspaceCreateRequest(this.body);
    Future<Either<Workspace, FlowyError>> send() {
      final command = Command.Workspace_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Workspace.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class WorkspaceDeleteRequest {
    IdentifiableEntity body;
    WorkspaceDeleteRequest(this.body);
    Future<Either<Workspace, FlowyError>> send() {
      final command = Command.Workspace_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Workspace.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class WorkspaceUpdateRequest {
    WorkspaceChangeset body;
    WorkspaceUpdateRequest(this.body);
    Future<Either<Workspace, FlowyError>> send() {
      final command = Command.Workspace_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Workspace.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class WorkspaceQueryRequest {
    WorkspaceQuery body;
    WorkspaceQueryRequest(this.body);
    Future<Either<WorkspaceQueryResult, FlowyError>> send() {
      final command = Command.Workspace_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = WorkspaceQueryResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class ViewCreateRequest {
    ViewCreation body;
    ViewCreateRequest(this.body);
    Future<Either<ViewCreation, FlowyError>> send() {
      final command = Command.View_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = ViewCreation.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class ViewDeleteRequest {
    IdentifiableEntity body;
    ViewDeleteRequest(this.body);
    Future<Either<View, FlowyError>> send() {
      final command = Command.View_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = View.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class ViewUpdateRequest {
    ViewChangeset body;
    ViewUpdateRequest(this.body);
    Future<Either<View, FlowyError>> send() {
      final command = Command.View_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = View.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class ViewQueryRequest {
    ViewQuery body;
    ViewQueryRequest(this.body);
    Future<Either<ViewQueryResult, FlowyError>> send() {
      final command = Command.View_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = ViewQueryResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class GridViewCreateRequest {
    GridViewCreation body;
    GridViewCreateRequest(this.body);
    Future<Either<GridViewCreationResult, FlowyError>> send() {
      final command = Command.Grid_View_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = GridViewCreationResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class ViewDisplayUpdateRequest {
    ViewDisplayChangeset body;
    ViewDisplayUpdateRequest(this.body);
    Future<Either<ViewDisplay, FlowyError>> send() {
      final command = Command.View_Display_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = ViewDisplay.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class TableCreateRequest {
    TableCreation body;
    TableCreateRequest(this.body);
    Future<Either<TableCreation, FlowyError>> send() {
      final command = Command.Table_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = TableCreation.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class TableDeleteRequest {
    IdentifiableEntity body;
    TableDeleteRequest(this.body);
    Future<Either<FYTable, FlowyError>> send() {
      final command = Command.Table_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = FYTable.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class TableUpdateRequest {
    FYTableChangeset body;
    TableUpdateRequest(this.body);
    Future<Either<FYTable, FlowyError>> send() {
      final command = Command.Table_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = FYTable.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class TableQueryRequest {
    TableQuery body;
    TableQueryRequest(this.body);
    Future<Either<TableQueryResult, FlowyError>> send() {
      final command = Command.Table_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = TableQueryResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class RowCreateRequest {
    RowCreation body;
    RowCreateRequest(this.body);
    Future<Either<Row, FlowyError>> send() {
      final command = Command.Row_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Row.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class RowDeleteRequest {
    IdentifiableEntity body;
    RowDeleteRequest(this.body);
    Future<Either<Row, FlowyError>> send() {
      final command = Command.Row_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Row.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class RowUpdateRequest {
    RowChangeset body;
    RowUpdateRequest(this.body);
    Future<Either<Row, FlowyError>> send() {
      final command = Command.Row_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Row.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class RowQueryRequest {
    RowQuery body;
    RowQueryRequest(this.body);
    Future<Either<RowQueryResult, FlowyError>> send() {
      final command = Command.Row_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = RowQueryResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class FieldCreateRequest {
    FieldCreation body;
    FieldCreateRequest(this.body);
    Future<Either<Field, FlowyError>> send() {
      final command = Command.Field_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Field.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class FieldDeleteRequest {
    IdentifiableEntity body;
    FieldDeleteRequest(this.body);
    Future<Either<Field, FlowyError>> send() {
      final command = Command.Field_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Field.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class FieldUpdateRequest {
    FieldChangeset body;
    FieldUpdateRequest(this.body);
    Future<Either<Field, FlowyError>> send() {
      final command = Command.Field_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Field.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class FieldQueryRequest {
    FieldQuery body;
    FieldQueryRequest(this.body);
    Future<Either<FieldQueryResult, FlowyError>> send() {
      final command = Command.Field_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = FieldQueryResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class AppCreateRequest {
    AppCreation body;
    AppCreateRequest(this.body);
    Future<Either<App, FlowyError>> send() {
      final command = Command.App_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = App.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class AppDeleteRequest {
    IdentifiableEntity body;
    AppDeleteRequest(this.body);
    Future<Either<App, FlowyError>> send() {
      final command = Command.App_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = App.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class AppUpdateRequest {
    AppChangeset body;
    AppUpdateRequest(this.body);
    Future<Either<App, FlowyError>> send() {
      final command = Command.App_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = App.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class AppQueryRequest {
    AppQuery body;
    AppQueryRequest(this.body);
    Future<Either<AppQueryResult, FlowyError>> send() {
      final command = Command.App_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = AppQueryResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class CellCreateRequest {
    CellCreation body;
    CellCreateRequest(this.body);
    Future<Either<Cell, FlowyError>> send() {
      final command = Command.Cell_Create;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Cell.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class CellDeleteRequest {
    IdentifiableEntity body;
    CellDeleteRequest(this.body);
    Future<Either<Cell, FlowyError>> send() {
      final command = Command.Cell_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Cell.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class CellUpdateRequest {
    CellChangeset body;
    CellUpdateRequest(this.body);
    Future<Either<Cell, FlowyError>> send() {
      final command = Command.Cell_Update;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = Cell.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class CellQueryRequest {
    CellQuery body;
    CellQueryRequest(this.body);
    Future<Either<CellQueryResult, FlowyError>> send() {
      final command = Command.Cell_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = CellQueryResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class UserQueryRequest {
    Uint8List? body;
    UserQueryRequest();
    Future<Either<UserQueryResult, FlowyError>> send() {
      final command = Command.User_Query;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return asyncQuery(request).then((response) {
        try {
          if (response.hasErr()) {
            return right(FlowyError.from(response));
          } else {
            final pb = UserQueryResult.fromBuffer(response.body);
            return left(pb);
          }
        } catch (e, s) {
          final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
          return right(error);
        }

      });
    }
}
class UserCheckRequest {
    Uint8List? body;
    UserCheckRequest();
    Future<Either<User, FlowyError>> send() {
      final command = Command.User_Check;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return asyncQuery(request).then((response) {
        try {
          if (response.hasErr()) {
            return right(FlowyError.from(response));
          } else {
            final pb = User.fromBuffer(response.body);
            return left(pb);
          }
        } catch (e, s) {
          final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
          return right(error);
        }

      });
    }
}
class UserSignInRequest {
    UserSignIn body;
    UserSignInRequest(this.body);
    Future<Either<UserSignInResult, FlowyError>> send() {
      final command = Command.User_Sign_In;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = UserSignInResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class UserSignUpRequest {
    UserSignUp body;
    UserSignUpRequest(this.body);
    Future<Either<UserSignUpResult, FlowyError>> send() {
      final command = Command.User_Sign_Up;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = UserSignUpResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class UserSignOutRequest {
    UserSignOut body;
    UserSignOutRequest(this.body);
    Future<Either<ResponsePacket, FlowyError>> send() {
      final command = Command.User_Sign_Out;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            return left(response);
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class UserActiveRequest {
    User body;
    UserActiveRequest(this.body);
    Future<Either<ResponsePacket, FlowyError>> send() {
      final command = Command.User_Active;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            return left(response);
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class UserMobileCodeRequest {
    VerificationCodeRequest body;
    UserMobileCodeRequest(this.body);
    Future<Either<VerificationCodeResponse, FlowyError>> send() {
      final command = Command.User_Mobile_Code;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = VerificationCodeResponse.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class UserAuthInputRequest {
    UserAuthInput body;
    UserAuthInputRequest(this.body);
    Future<Either<UserAuthInput, FlowyError>> send() {
      final command = Command.User_Auth_Input;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = UserAuthInput.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class BucketSetRequest {
    BucketItem body;
    BucketSetRequest(this.body);
    Future<Either<ResponsePacket, FlowyError>> send() {
      final command = Command.Bucket_Set;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            return left(response);
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class BucketGetRequest {
    BucketItem body;
    BucketGetRequest(this.body);
    Future<Either<BucketItem, FlowyError>> send() {
      final command = Command.Bucket_Get;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncQuery(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = BucketItem.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class BucketDeleteRequest {
    BucketItem body;
    BucketDeleteRequest(this.body);
    Future<Either<ResponsePacket, FlowyError>> send() {
      final command = Command.Bucket_Delete;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            return left(response);
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
class CSVImportRequest {
    FlowyResource body;
    CSVImportRequest(this.body);
    Future<Either<ShareResult, FlowyError>> send() {
      final command = Command.CSV_Import;
      var request = RequestPacket.create()
      ..command = command
      ..id = uuid();
      return protobufToBytes(body).fold(
        (req_bytes) {
          request.body = req_bytes;
          return asyncCommand(request).then((response) {
            try {
              if (response.hasErr()) {
                return right(FlowyError.from(response));
              } else {
                final pb = ShareResult.fromBuffer(response.body);
                return left(pb);
              }

            } catch (e, s) {
              final error = FlowyError.fromError('error: ${e.runtimeType}. Stack trace: $s', StatusCode.ProtobufDeserializeError);
              return right(error);
            }
          });
        },
        (err) => Future(() {
            final error = FlowyError.fromError(err, StatusCode.ProtobufSerializeError);
            return right(error);
        }),
      );
    }
}
