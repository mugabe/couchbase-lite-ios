Pod::Spec.new do |s|
    s.name                  = 'CouchbaseLiteLegacy'
    s.version               = '1.x'
    s.license               = 'Apache License, Version 2.0'
    s.homepage              = 'https://github.com/couchbase/couchbase-lite-ios'
    s.summary               = 'An embedded syncable NoSQL database for iOS and MacOS apps.'
    s.author                = 'Couchbase'
    s.source                = { :git => 'git@github.com:pridemon/ios-utils.git', :branch => "podspec", :submodules => true }
  
    s.prepare_command = <<-CMD
      sh BuildScripts/BuildFramework.sh s.version s.version community ios
    CMD
  
    s.ios.preserve_paths = 'zipfile_staging/CouchbaseLiteLegacy.framework'
    s.ios.vendored_frameworks = 'zipfile_staging/CouchbaseLiteLegacy.framework'
  
    s.ios.deployment_target  = '9.0'
  end