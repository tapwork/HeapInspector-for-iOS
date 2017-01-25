Pod::Spec.new do |s|
  s.name     = 'HeapInspector'
  s.version  = '1.0'
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.summary = 'Find memory issues & leaks in your iOS app without instruments'
  s.description  = 'HeapInspector is a debug tool that **monitors the memory heap** with backtrace recording in your iOS app. You can discover memory leaks, no longer used objects, abandoned memory and more issues directly on your device without ever starting Instruments.'
  s.homepage = 'https://github.com/tapwork/HeapInspector'
  s.social_media_url = 'https://twitter.com/cmenschel'
  s.authors  = { 'Christian Menschel' => 'christian@tapwork.de' }
  s.source = {
    :git => 'https://github.com/tapwork/HeapInspector.git',
    :tag => s.version.to_s
  }
  s.ios.deployment_target = '8.0'
  s.source_files = 'src/**.{h,m}'
  non_arc_files = 'src/NSObject+HeapInspector.{h,m}'
  s.exclude_files = non_arc_files
  s.requires_arc = true
  s.subspec 'no-arc' do |sna|
    sna.requires_arc = false
    sna.source_files = non_arc_files
  end
end
