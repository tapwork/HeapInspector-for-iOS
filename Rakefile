desc "Bootstraps the repo"
task :bootstrap do
  sh("gem install bundler")
  sh("bundle install")
  sh("cd Example/HeapInspectorExample && bundle exec pod install")
end

desc "Runs the specs"
task :spec do
  sh("xcodebuild -workspace Example/HeapInspectorExample/HeapInspectorExample.xcworkspace -scheme HeapInspectorExample -destination platform='iOS Simulator',OS=10.1,name='iPhone 6s' clean build test -sdk iphonesimulator | xcpretty")
end
