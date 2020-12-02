Pod::Spec.new do |s|
    s.name                  = 'CouchbaseLiteLegacy'
    s.version               = '1.0.0'
    s.license               = 'Apache License, Version 2.0'
    s.homepage              = 'https://github.com/couchbase/couchbase-lite-ios'
    s.summary               = 'An embedded syncable NoSQL database for iOS and MacOS apps.'
    s.author                = 'Couchbase'
    s.source                = { :git => 'git@github.com:mugabe/couchbase-lite-ios-1.x-xcode11.git', :branch => "podspec", :submodules => true }
  
    s.prepare_command = <<-CMD
      sh BuildScripts/BuildFramework.sh 1.0.0 1.0.0 community ios
    CMD
  
    s.ios.preserve_paths = 'zipfile_staging/CouchbaseLiteLegacy.framework'
    s.ios.vendored_frameworks = 'zipfile_staging/CouchbaseLiteLegacy.framework'
  
    s.ios.deployment_target  = '9.0'
  end