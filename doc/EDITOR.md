

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


```
// ┌────────────────────────┐  ┌──────────────────┐
// │   RawGestureDetector   │─▶│   RenderEditor   │──┐
// └────────────────────────┘  └──────────────────┘  │
//                                                   │
//                1. pass the gesture event          │
//                                                   │
//                                                   │
//            ┌───────────────────────────────────┐  │   ┌────────────────┐             ┌──────────────────┐   ┌──────────────────────────────┐
//            │RawEditorStateTextInputClientMixin │──┼──▶│QuillController │◀──listen────│   RenderState    │──▶│  _didChangeTextEditingValue  │
//            └───────────────────────────────────┘  │   └────────────────┘             └──────────────────┘   └──────────────────────────────┘
//                                                   │            │                               ▲                            │
//                1. pass the text input event       │            │                               │                            ▼
//                                                   │            └─────2. notify change──────────┘           ┌─────────────────────────────────┐
//                                                   │                                                        │    _onChangeTextEditingValue    │
//                 ┌─────────────────────────────┐   │                                                        └─────────────────────────────────┘
//                 │ RawEditorStateKeyboardMixin │───┘                                                                         │
//                 └─────────────────────────────┘                                                                             ▼
//                                                                                                                 ┌──────────────────────┐   Update the ScrollController's pos after
//                1. pass the keyboard cur/ delete/ shortcut event                                                 │  _showCaretOnScreen  │   post frame
//                                                                                                                 └──────────────────────┘
//                                                                                                                             │
//                                                                                                                             ▼
//                                                                                                                 ┌──────────────────────┐
//                                                                                                                 │ Config cursor timer  │
//                                                                                                                 └──────────────────────┘
//                                                                                                                             │
//                                                                                                                             ▼
//                                                                                                                 ┌───────────────────────┐  ┌───────────────────────────────────┐
//                                                                                                                 │ addPostFrameCallback  │─▶│_updateOrDisposeSelectionOverlayIfN│
//                                                                                                                 └───────────────────────┘  └───────────────────────────────────┘
//                                                                                                                             │
//                                                                                                                             │
//                                                                                                                             ▼
//                                                                                                                      ┌────────────┐
//                                                                                                                      │  setState  │        make the RenderState to rebuild
//                                                                                                                      └────────────┘


```