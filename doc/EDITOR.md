

```
//          Widget                                 Element                      RenderObject
//
//                                    │                                │
//
//    ┌─────────────────────┐         │   ┌────────────────────────┐   │  ┌─────────────────────────┐
//    │ RenderObjectWidget  │◀────────────│    _TextLineElement    │─────▶│ RenderEditableTextLine  │
//    └─────────────────────┘         │   └────────────────────────┘   │  └─────────────────────────┘
//               △                                     │                               │
//               │                    │                │               │     ┌─────────▽────────┐
//               │                                     ▽                     │RenderEditableBox │
//    ┌────────────────────┐          │    ┌──────────────────────┐    │     └──────────────────┘
// ┌──│  EditableTextLine  │               │ RenderObjectElement  │                    │
// │  └────────────────────┘          │    └──────────────────────┘    │               ▽
// │                                                                            ┌────────────┐
// │                                  │                                │        │ RenderBox  │
// │                                                                            └────────────┘
// │    body   ┌────────────┐         │                                │               │
// ├──────────▶│  TextLine  │                                                          ▽
// │           └────────────┘         │                                │        ┌─────────────┐
// │                                                                            │RenderObject │
// │           ┌────────────┐         │                                │        └─────────────┘
// └──────────▶│    Line    │
//             └────────────┘         │                                │
//
//                                    │                                │          Layout, size, painting and
// Widget: holds the config for a             Represents an actual                comositing
// piece of UI.                       │       piece of UI              │
//
//
```
