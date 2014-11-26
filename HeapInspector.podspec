Pod::Spec.new do |s|
  s.name     = 'HeapInspector'
  s.version  = '0.0.2'
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.summary = 'Find memory issues & leaks in your iOS app without instruments'
  s.description  = 'HeapInspector is an iOS debug tool that **monitors and snapshots the memory heap** in your iOS app. With HeapInspector you can discover memory leaks, no longer needed living objects and more issues directly on your device without ever starting Instruments.'
  s.homepage = 'https://github.com/tapwork/HeapInspector'
  s.social_media_url = 'https://twitter.com/cmenschel'
  s.authors  = { 'Christian Menschel' => 'christian@tapwork.de' }
  s.source = {
    :git => 'https://github.com/tapwork/HeapInspector.git',
    :tag => s.version.to_s
  }
  s.ios.deployment_target = '5.0'
  s.source_files = 'HeapInspector/**.{h,m}'
  non_arc_files = 'HeapInspector/NSObject+HeapInspector.{h,m}'
  s.exclude_files = non_arc_files
  s.requires_arc = true
  s.subspec 'no-arc' do |sna|
    sna.requires_arc = false
    sna.source_files = non_arc_files
  end
end
