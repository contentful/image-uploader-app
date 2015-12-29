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
pod 'ContentfulManagementAPI'
pod 'DJProgressHUD', :podspec => 'vendor/DJProgressHUD.podspec'
pod 'Dropbox-OSX-SDK', :inhibit_warnings => true
pod 'FormatterKit'
pod 'JNWCollectionView', :inhibit_warnings => true
pod 'KVOController'
pod 'MASPreferences'
pod 'Realm'
pod 'SSKeychain'

target "image-uploader" do

end

target "Uploader Tests" do

inherit! :search_paths

pod 'OCMock'

end
