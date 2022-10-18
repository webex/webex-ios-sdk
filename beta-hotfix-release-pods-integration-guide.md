 ## Guide for integrating beta/hotfix versions of WebexSDK and WebexBroadcastextensionKit pods into your projects
 1. Download and extract `WebexSDK.zip` and `WebexBroadcastExtensionKit.zip` from the beta/hotfix branch
 2. After extraction, the pods should be inside two folders: `WebexSDK` and `WebexBroadcastExtensionKit`
 3. Modify your project `Podfile` as the following example:

    ```ruby
    target 'KitchenSink' do
    use_frameworks!

    # Pods for KitchenSink
        pod 'WebexSDK', :path => '/path/to/WebexSDK'

    target 'KitchenSinkUITests' do
        # Pods for testing
    end

    end

    target 'KitchenSinkBroadcastExtension' do
    use_frameworks!

    # Pods for KitchenSinkBroadcastExtension 
    pod 'WebexBroadcastExtensionKit',:path => '/path/to/WebexBroadcastExtensionKit'
    end
    ```
