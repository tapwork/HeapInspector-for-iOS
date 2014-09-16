Pod::Spec.new do |s|
  s.name     = 'HeapInspector'
  s.version  = '0.0.1'
  s.license      = { :type => "MIT", :file => "LICENSE.md" }
  s.summary  = 'A iOS debugging tool to monitor the memory heap.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.social_media_url = 'https://twitter.com/cmenschel'
  s.authors  = { 'Christian Menschel' => 'christian@tapwork.de' }
  s.source   = { :git => 'https://git.tapwork.de/root/heapinspector.git', :tag => "0.0.1" }
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
