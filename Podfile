plugin 'cocoapods-keys', {
  :project => 'image-uploader',
  :keys => [
    'ContentfulOAuthClient',
    'DropboxOAuthKey',
    'DropboxOAuthSecret'
  ]}

source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.9'

pod 'IAmUpload'
pod 'ContentfulManagementAPI', :head
pod 'DJProgressHUD', :podspec => 'vendor/DJProgressHUD.podspec'
pod 'Dropbox-OSX-SDK', :inhibit_warnings => true
pod 'FormatterKit'
pod 'JNWCollectionView', :inhibit_warnings => true
pod 'KVOController'
pod 'MASPreferences'
pod 'Realm', '0.85.0'
pod 'SSKeychain'

target "Uploader Tests" do

inherit! :search_paths

pod 'OCMock'

end
