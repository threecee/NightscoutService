#!/usr/bin/env ruby
# add_watchos_platform.rb
# Adds watchOS 10.0 support to the NightscoutServiceKit target in NightscoutService.xcodeproj
# B.3.a Phase 3.A
#
# The NightscoutServiceKit framework contains no UIKit or LoopKitUI refs, so it can
# compile for watchOS without any source gating. The UI/Plugin targets remain iOS-only.
#
# Also removes the spurious LoopKitUI link dependency from NightscoutServiceKit —
# no source file in that target actually imports LoopKitUI, but it was linked in the
# Frameworks build phase, which breaks watchOS builds (LoopKitUI is iOS-only).

require 'xcodeproj'

PROJECT_PATH = File.expand_path('../NightscoutService.xcodeproj', __dir__)
TARGET_NAME  = 'NightscoutServiceKit'
WATCHOS_MIN  = '10.0'

proj = Xcodeproj::Project.open(PROJECT_PATH)

target = proj.targets.find { |t| t.name == TARGET_NAME }
abort "ERROR: Target '#{TARGET_NAME}' not found" unless target

puts "Found target: #{target.name}"
puts "Build configs: #{target.build_configurations.map(&:name).join(', ')}"

target.build_configurations.each do |config|
  settings = config.build_settings

  # 1. Expand SUPPORTED_PLATFORMS to include watchOS
  current_platforms = settings['SUPPORTED_PLATFORMS'] || 'iphoneos iphonesimulator'
  unless current_platforms.include?('watchos')
    settings['SUPPORTED_PLATFORMS'] = current_platforms + ' watchos watchsimulator'
    puts "[#{config.name}] Set SUPPORTED_PLATFORMS = #{settings['SUPPORTED_PLATFORMS']}"
  end

  # 2. Add watchOS deployment target
  settings['WATCHOS_DEPLOYMENT_TARGET'] = WATCHOS_MIN
  puts "[#{config.name}] Set WATCHOS_DEPLOYMENT_TARGET = #{WATCHOS_MIN}"

  # 3. Ensure APPLICATION_EXTENSION_API_ONLY = YES (watchOS extensions require this)
  settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  puts "[#{config.name}] Set APPLICATION_EXTENSION_API_ONLY = YES"

  # 4. TARGETED_DEVICE_FAMILY: add watch (4) to existing 1,2 (iPhone, iPad)
  current_family = settings['TARGETED_DEVICE_FAMILY'] || '1,2'
  unless current_family.include?('4')
    settings['TARGETED_DEVICE_FAMILY'] = current_family + ',4'
    puts "[#{config.name}] Set TARGETED_DEVICE_FAMILY = #{settings['TARGETED_DEVICE_FAMILY']}"
  end
end

# 5. Remove LoopKitUI from the NightscoutServiceKit Frameworks build phase.
#    No source in NightscoutServiceKit imports LoopKitUI; the link dep is spurious
#    and breaks watchOS builds since LoopKitUI is iOS-only.
frameworks_phase = target.frameworks_build_phase
before_count = frameworks_phase.files.count
frameworks_phase.files.reject! do |bf|
  display_name = bf.display_name rescue nil
  file_ref = bf.file_ref rescue nil
  name = display_name || (file_ref.respond_to?(:path) ? File.basename(file_ref.path.to_s) : nil) || ''
  remove = name.include?('LoopKitUI')
  puts "Removing from Frameworks phase: #{name}" if remove
  remove
end
after_count = frameworks_phase.files.count
puts "Frameworks phase: #{before_count} -> #{after_count} files"

proj.save
puts "\nProject saved: #{PROJECT_PATH}"
puts "Done. NightscoutServiceKit now targets iOS 15.1+ and watchOS #{WATCHOS_MIN}+"
