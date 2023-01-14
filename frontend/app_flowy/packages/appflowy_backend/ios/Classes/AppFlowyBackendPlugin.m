#import "AppFlowyBackendPlugin.h"
#if __has_include(<appflowy_backend/appflowy_backend-Swift.h>)
#import <appflowy_backend/appflowy_backend-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "appflowy_backend-Swift.h"
#endif

@implementation AppFlowyBackendPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAppFlowyBackendPlugin registerWithRegistrar:registrar];
}
@end
