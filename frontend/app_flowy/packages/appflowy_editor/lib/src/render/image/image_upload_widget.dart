import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:appflowy_editor/src/render/style/editor_style.dart';
=======
import 'package:appflowy_editor/src/render/image/file_picker_dialog.dart';
=======
>>>>>>> c066f53cd (feat: pick local image files)
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
>>>>>>> 3b501dd6c (feat: upload via file 🌟)
import 'package:flutter/material.dart';

OverlayEntry? _imageUploadMenu;
EditorState? _editorState;
String? localFile;
void showImageUploadMenu(
  EditorState editorState,
  SelectionMenuService menuService,
  BuildContext context,
) {
  menuService.dismiss();

  _imageUploadMenu?.remove();
  _imageUploadMenu = OverlayEntry(builder: (context) {
    return Positioned(
      top: menuService.topLeft.dy,
      left: menuService.topLeft.dx,
      child: Material(
        child: ImageUploadMenu(
          editorState: editorState,
          onSubmitted: (text) {
            // _dismissImageUploadMenu();
            editorState.insertImageNode(text, 'file');
          },
          onUpload: (text) {
            // _dismissImageUploadMenu();
            editorState.insertImageNode(text, 'network');
          },
        ),
      ),
    );
  });

  Overlay.of(context)?.insert(_imageUploadMenu!);

  editorState.service.selectionService.currentSelection
      .addListener(_dismissImageUploadMenu);
}

void _dismissImageUploadMenu() {
  _imageUploadMenu?.remove();
  _imageUploadMenu = null;

  _editorState?.service.selectionService.currentSelection
      .removeListener(_dismissImageUploadMenu);
  _editorState = null;
}

class ImageUploadMenu extends StatefulWidget {
  const ImageUploadMenu({
    Key? key,
    required this.onSubmitted,
    required this.onUpload,
    this.editorState,
  }) : super(key: key);

  final void Function(String text) onSubmitted;
  final void Function(String text) onUpload;
  final EditorState? editorState;

  @override
  State<ImageUploadMenu> createState() => _ImageUploadMenuState();
}

class _ImageUploadMenuState extends State<ImageUploadMenu>
    with TickerProviderStateMixin {
  String? _fileName;
  String? _saveAsFileName;
  String? src;
  List<PlatformFile>? _paths;
  String? _directoryPath;
  String? _extension;
  bool _isLoading = false;
  bool _userAborted = false;
  bool _multiPick = false;
  FileType _pickingType = FileType.any;

  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();
<<<<<<< HEAD

  EditorStyle? get style => widget.editorState?.editorStyle;

=======
>>>>>>> 096eeec1e (feat: upload via local file 🌟)
  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _pickFiles() async {
    _resetState();
    try {
      _directoryPath = null;
      _paths = (await FilePicker.platform.pickFiles(
              type: _pickingType,
              onFileLoading: (FilePickerStatus status) => print(status),
              allowedExtensions: ['jpg', 'png', 'gif']))
          ?.files;
    } on PlatformException catch (e) {
      _logException('Unsupported operation' + e.toString());
    } catch (e) {
      _logException(e.toString());
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      for (var e in _paths!) {
        _fileName = e.name;
      }
      for (var e in _paths!) {
        src = e.path;
      }

      _userAborted = _paths == null;

      File srcImg = File('$src');
      copyFile(srcImg, _fileName!);
    });
  }

  Future<void> copyFile(File path, String name) async {
    Directory appDir = await getApplicationDocumentsDirectory();
    //TODO: Rewrite for it to autoselect dir based on release type 
    Directory('${appDir.path}/flowy_dev/image').create();
    path.copy('${appDir.path}/flowy_dev/image/$name');
    localFile = '${appDir.path}/flowy_dev/image/$name';
    widget.onSubmitted(localFile!);
  }

  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _directoryPath = null;
      _fileName = null;
      _paths = null;
      _saveAsFileName = null;
      _userAborted = false;
    });
  }

  void _logException(String message) {
    print(message);
  }

  @override
  Widget build(BuildContext context) {
    TabController _tabController =
        //BUG: Tab Controller still goes back to default tab
        TabController(initialIndex: 1, length: 2, vsync: this);
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: style?.selectionMenuBackgroundColor ?? Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            spreadRadius: 1,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
        // borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TabBar(
            controller: _tabController,
            tabs: const [
              Text(
                'Upload Image',
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                'URL Image',
                textAlign: TextAlign.left,
                style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
          SizedBox(
              height: 200.0,
              child: TabBarView(controller: _tabController, children: <Widget>[
                InkWell(
                  onTap: (() => _pickFiles()),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[_buildFileInput(context)]),
                ),
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildURLInput(),
                      const SizedBox(height: 15.0),
                      _buildUploadButton(context)
                    ])
              ])),
          const SizedBox(height: 18.0),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildHeader(BuildContext context) {
    return Text(
      'URL Image',
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: 14.0,
        color: style?.selectionMenuItemTextColor ?? Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInput() {
=======
  Widget _buildURLInput() {
>>>>>>> 096eeec1e (feat: upload via local file 🌟)
    return TextField(
      focusNode: _focusNode,
      style: const TextStyle(fontSize: 14.0),
      textAlign: TextAlign.left,
      controller: _textEditingController,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: 'URL',
        hintStyle: const TextStyle(fontSize: 14.0),
        contentPadding: const EdgeInsets.all(16.0),
        isDense: true,
        suffixIcon: IconButton(
          padding: const EdgeInsets.all(4.0),
          icon: const FlowySvg(
            name: 'clear',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            _textEditingController.clear();
          },
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
          borderSide: BorderSide(color: Color(0xFFBDBDBD)),
        ),
      ),
    );
  }

  Widget _buildFileInput(BuildContext context) {
    return InkWell(
      child: Column(
        children: const <Widget>[
          Icon(Icons.image, color: Colors.black, size: 48.0),
          SizedBox(height: 15.0),
          Text(
            'Drop Image/Click To Upload',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14.0,
                color: Colors.black,
                fontWeight: FontWeight.w500),
          )
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 48,
      child: TextButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(const Color(0xFF00BCF0)),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        onPressed: () {
          widget.onUpload(_textEditingController.text);
        },
        child: const Text(
          'Upload',
          style: TextStyle(color: Colors.white, fontSize: 14.0),
        ),
      ),
    );
  }
}

extension on EditorState {
  void insertImageNode(String src, String type) {
    final selection = service.selectionService.currentSelection.value;
    if (selection == null) {
      return;
    }
    final imageNode = Node(
      type: 'image',
      attributes: {
        'image_src': src,
        'align': 'center',
        'type': type,
      },
    );
    print(imageNode);
    final transaction = this.transaction;
    transaction.insertNode(
      selection.start.path,
      imageNode,
    );
    apply(transaction);
  }
}
