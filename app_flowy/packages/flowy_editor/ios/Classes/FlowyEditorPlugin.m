#import "FlowyEditorPlugin.h"
#if __has_include(<flowy_editor/flowy_editor-Swift.h>)
#import <flowy_editor/flowy_editor-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flowy_editor-Swift.h"
#endif

@implementation FlowyEditorPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlowyEditorPlugin registerWithRegistrar:registrar];
}
@end
