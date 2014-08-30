Pod::Spec.new do |s|
  s.name     = 'HeapInspector'
  s.version  = '1.0.0'
  s.license  = 'MIT'
  s.summary  = 'A iOS debugging tool to monitor the memory heap.'
  s.homepage = 'https://github.com/AFNetworking/AFNetworking'
  s.social_media_url = 'https://twitter.com/cmenschel'
  s.authors  = { 'Christian Menschel' => 'christian@tapwork.de' }
  s.source   = { :git => 'https://github.com/AFNetworking/AFNetworking.git', :tag => "2.3.1" }
  s.requires_arc = true
  s.source_files = 'HeapInspector/**.{h,m}'
end
