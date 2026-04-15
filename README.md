# ConnectFloatingChatDemo

An Xcode sample app that embeds the Amazon Connect Chat iOS binary XCFramework and shows a floating chat bubble above both SwiftUI and UIKit screens using a fully local mock transcript.

Included binaries:

- `AmazonConnectChatIOS.xcframework` version `2.0.12`
- `AWSCore.xcframework` version `2.41.0`
- `AWSConnectParticipant.xcframework` version `2.41.0`

## What This Demo Does

- Shows a floating chat bubble above any screen using a dedicated overlay `UIWindow`
- Expands the bubble into a chat panel built in SwiftUI
- Works from a native SwiftUI screen and a native UIKit screen
- Uses local mock messages instead of live Amazon Connect API calls
- Lets you review the feasibility of the floating support widget UX without backend setup

## Open In Xcode

1. Open [ConnectFloatingChatDemo.xcodeproj](/Users/shravangudikadi/Documents/New%20project/ConnectFloatingChatDemo/ConnectFloatingChatDemo.xcodeproj)
2. Select your signing team
3. Build and run on an iOS simulator or device
4. Open the `POC` tab and tap `Start Mock Chat`

## POC Run Flow

1. Run the app
2. Tap `Start Mock Chat` from the `POC` tab
3. Or tap `Show Floating Bubble` from the `SwiftUI` or `UIKit` tab
4. Open the bubble and send sample messages like `Where is my order?` or `I want a refund`
5. Review the floating panel behavior, transcript rendering, and mock agent responses

## Notes

- This sample focuses on the client app, overlay behavior, and binary framework wiring
- The Amazon Connect SDK binaries are still bundled into the project for feasibility review, but this build does not call a live backend
- The bundled `AmazonConnectChatIOS.xcframework` needed a local Swift interface compatibility patch to build on Xcode `26.3` in this workspace
