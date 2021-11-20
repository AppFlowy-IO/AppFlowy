#import "FlowySdkPlugin.h"
#if __has_include(<flowy_sdk/flowy_sdk-Swift.h>)
#import <flowy_sdk/flowy_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flowy_sdk-Swift.h"
#endif

@implementation FlowySdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlowySdkPlugin registerWithRegistrar:registrar];
}
@end
