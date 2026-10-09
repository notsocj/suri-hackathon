require 'xcodeproj'
root = File.expand_path('..', __dir__)
project = Xcodeproj::Project.new(File.join(root, 'Suri.xcodeproj'))
app = project.new_target(:application, 'Suri', :ios, '18.0')
share = project.new_target(:app_extension, 'SuriShare', :ios, '18.0')
tests = project.new_target(:ui_test_bundle, 'SuriUITests', :ios, '18.0')
tests.build_configurations.each { |c| c.build_settings.merge!({'SWIFT_VERSION'=>'6.0','PRODUCT_BUNDLE_IDENTIFIER'=>'ph.suri.app.uitests','GENERATE_INFOPLIST_FILE'=>'YES','TEST_TARGET_NAME'=>'Suri','CODE_SIGN_STYLE'=>'Automatic'}) }
test_group = project.main_group.new_group('SuriUITests', 'SuriUITests')
tests.source_build_phase.add_file_reference(test_group.new_file('SuriUITests.swift'))
tests.add_dependency(app)
integration = project.new_target(:unit_test_bundle, 'SuriIntegrationTests', :ios, '18.0')
integration.build_configurations.each { |c| c.build_settings.merge!({'SWIFT_VERSION'=>'6.0','PRODUCT_BUNDLE_IDENTIFIER'=>'ph.suri.app.integration-tests','GENERATE_INFOPLIST_FILE'=>'YES','TEST_HOST'=>'$(BUILT_PRODUCTS_DIR)/Suri.app/Suri','BUNDLE_LOADER'=>'$(TEST_HOST)','CODE_SIGN_STYLE'=>'Automatic'}) }
integration_group = project.main_group.new_group('SuriIntegrationTests', 'SuriIntegrationTests')
integration.source_build_phase.add_file_reference(integration_group.new_file('CaptureTests.swift'))
integration.add_dependency(app)
[app, share].each do |target|
  target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_IDENTITY[sdk=iphonesimulator*]'] = '-'
    config.build_settings['CODE_SIGN_STYLE[sdk=iphonesimulator*]'] = 'Manual'
    config.build_settings['CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]'] = target == app ? 'SuriApp/Simulator.entitlements' : 'SuriShareExtension/Simulator.entitlements'
    config.build_settings.merge!({
      'SWIFT_VERSION' => '6.0', 'SWIFT_STRICT_CONCURRENCY' => 'complete',
      'SWIFT_APPROACHABLE_CONCURRENCY' => 'YES', 'SWIFT_DEFAULT_ACTOR_ISOLATION' => 'MainActor',
      'TARGETED_DEVICE_FAMILY' => '1', 'CODE_SIGN_STYLE' => 'Automatic',
      'GENERATE_INFOPLIST_FILE' => 'NO', 'CURRENT_PROJECT_VERSION' => '1',
      'MARKETING_VERSION' => '1.0.0', 'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES'
    })
  end
end
app.build_configurations.each { |c| c.build_settings.merge!({'PRODUCT_BUNDLE_IDENTIFIER'=>'ph.suri.app','INFOPLIST_FILE'=>'SuriApp/Info.plist','CODE_SIGN_ENTITLEMENTS'=>'SuriApp/Suri.entitlements','ASSETCATALOG_COMPILER_APPICON_NAME'=>'AppIcon'}) }
share.build_configurations.each { |c| c.build_settings.merge!({'PRODUCT_BUNDLE_IDENTIFIER'=>'ph.suri.app.share','INFOPLIST_FILE'=>'SuriShareExtension/Info.plist','CODE_SIGN_ENTITLEMENTS'=>'SuriShareExtension/SuriShare.entitlements','APPLICATION_EXTENSION_API_ONLY'=>'YES','SKIP_INSTALL'=>'YES'}) }
[['SuriApp', app], ['SuriShareExtension', share]].each do |directory, target|
  group = project.main_group.new_group(directory, directory)
  Dir.glob(File.join(root, directory, '**', '*.swift')).sort.each do |path|
    relative = path.delete_prefix(File.join(root, directory) + '/')
    target.source_build_phase.add_file_reference(group.new_file(relative))
  end
  if directory == 'SuriApp'
    resources = group.new_group('Resources', 'Resources')
    Dir.glob(File.join(root, directory, 'Resources', '*')).sort.each do |path|
      target.resources_build_phase.add_file_reference(resources.new_file(File.basename(path)))
    end
  end
end
core = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
shared = project.main_group.new_group('Shared', 'Shared')
shared_file = shared.new_file('SharedInbox.swift')
[app, share].each { |target| target.source_build_phase.add_file_reference(shared_file) }
core.relative_path = '.'
project.root_object.package_references << core
[app, share].each do |target|
  dependency = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dependency.product_name = 'SuriCore'
  target.package_product_dependencies << dependency
  ref = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  ref.product_ref = dependency
  target.frameworks_build_phase.files << ref
end
bridge = project.main_group.new_group('Inference', 'SuriApp/InferenceBridge')
app.source_build_phase.add_file_reference(bridge.new_file('SuriInference.cpp'))
bridge.new_file('SuriInference.h')
app.build_configurations.each do |c|
  c.build_settings.merge!({
    'SWIFT_OBJC_BRIDGING_HEADER'=>'SuriApp/InferenceBridge/SuriInference.h',
    'CLANG_CXX_LANGUAGE_STANDARD'=>'c++17',
    'HEADER_SEARCH_PATHS'=>['$(inherited)','$(SRCROOT)/.build/LlamaSource/include','$(SRCROOT)/.build/LlamaSource/ggml/include'],
    'OTHER_LDFLAGS'=>['$(inherited)','-lc++','-framework','Accelerate'],
    'OTHER_LDFLAGS[sdk=iphonesimulator*]'=>['$(inherited)','-lc++','-framework','Accelerate','$(SRCROOT)/.build/LlamaSimulatorCPU/src/libllama.a','$(SRCROOT)/.build/LlamaSimulatorCPU/ggml/src/libggml.a','$(SRCROOT)/.build/LlamaSimulatorCPU/ggml/src/libggml-base.a','$(SRCROOT)/.build/LlamaSimulatorCPU/ggml/src/libggml-cpu.a','$(SRCROOT)/.build/LlamaSimulatorCPU/ggml/src/ggml-blas/libggml-blas.a'],
    'OTHER_LDFLAGS[sdk=iphoneos*]'=>['$(inherited)','-lc++','-framework','Accelerate','$(SRCROOT)/.build/LlamaDeviceCPU/src/libllama.a','$(SRCROOT)/.build/LlamaDeviceCPU/ggml/src/libggml.a','$(SRCROOT)/.build/LlamaDeviceCPU/ggml/src/libggml-base.a','$(SRCROOT)/.build/LlamaDeviceCPU/ggml/src/libggml-cpu.a','$(SRCROOT)/.build/LlamaDeviceCPU/ggml/src/ggml-blas/libggml-blas.a']
  })
end
app.add_dependency(share)
embed = app.new_copy_files_build_phase('Embed App Extensions')
embed.dst_subfolder_spec = '13'
ref = embed.add_file_reference(share.product_reference)
ref.settings = {'ATTRIBUTES'=>['RemoveHeadersOnCopy']}
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(tests)
scheme.add_test_target(integration)
scheme.save_as(File.join(root, 'Suri.xcodeproj'), 'Suri', true)
puts 'Generated Suri.xcodeproj'
