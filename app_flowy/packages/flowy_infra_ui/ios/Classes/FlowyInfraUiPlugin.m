#import "FlowyInfraUiPlugin.h"
#if __has_include(<flowy_infra_ui/flowy_infra_ui-Swift.h>)
#import <flowy_infra_ui/flowy_infra_ui-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flowy_infra_ui-Swift.h"
#endif

@implementation FlowyInfraUiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlowyInfraUiPlugin registerWithRegistrar:registrar];
}
@end
