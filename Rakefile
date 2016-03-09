desc "Bootstraps the repo"
task :bootstrap do
  sh("bundle")
  sh("cd Example/HeapInspectorExample && bundle exec pod install")
  sh("cd Example/SwiftExample && bundle exec pod install")
end

desc "Runs the specs"
task :spec do
  sh("xcodebuild -workspace Example/HeapInspectorExample/HeapInspectorExample.xcworkspace -scheme HeapInspectorExample -destination platform='iOS Simulator',OS=9.0,name='iPhone 6s' clean build test -sdk iphonesimulator | xcpretty -t -c; exit ${PIPESTATUS[0]}")
  #sh("xcodebuild -workspace Example/SwiftExample/SwiftExample.xcworkspace -scheme SwiftExample -destination platform='iOS Simulator',OS=9.0,name='iPhone 6s' clean build test -sdk iphonesimulator | xcpretty -t -c; exit ${PIPESTATUS[0]}")
end
