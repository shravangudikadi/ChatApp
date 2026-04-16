# Build In-House Chat Summary

## Recommendation

Build this chat experience in-house.

## Why

Amazon Connect's iOS SDK is designed for customer support chat on top of Amazon Connect, not for a product-native chat experience where users interact primarily with our app data and workflows.

## What AWS Officially Says

- The iOS SDK "wraps the Amazon Connect Participant Service APIs" and handles chat session and WebSocket logic.
  Source: [Amazon Connect Chat SDK for iOS README](https://github.com/amazon-connect/amazon-connect-chat-ios)
- It still requires our own backend to call `StartChatContact` before the mobile SDK can connect.
  Source: [Amazon Connect Chat SDK for iOS README](https://github.com/amazon-connect/amazon-connect-chat-ios)
- AWS positions the mobile SDKs around network and session management plus a sample UX app, not as a standalone reusable UI framework for arbitrary backends.
  Source: [AWS mobile SDK announcement](https://aws.amazon.com/about-aws/whats-new/2024/10/amazon-connect-ios-android-sdks-chat-experiences/)
- Real chat startup depends on `StartChatContact`, then participant connection creation.
  Sources: [StartChatContact API](https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html), [CreateParticipantConnection API](https://docs.aws.amazon.com/connect/latest/APIReference/API_connect-participant_CreateParticipantConnection.html)

## Why Amazon Connect Is A Mismatch For Our Use Case

- Our goal is an in-app conversational layer over our own product data.
- Amazon Connect is optimized for contact center workflows:
  - routing
  - queues
  - agents
  - bot-to-agent handoff
  - transcripts
  - participant session management
- It does not natively solve:
  - app-specific data retrieval
  - app actions and workflows
  - our internal business logic orchestration
  - a reusable UI-only SDK approach with our own chat backend

## In-House vs Amazon Connect

| Area | In-house build | Amazon Connect SDK |
|---|---|---|
| Primary fit | Product-native app chat | Contact center / support chat |
| Backend control | Full control over our own APIs and data models | Must conform to Connect chat/session model |
| UI flexibility | Fully tailored to our app | SDK is not primarily a drop-in UI kit |
| User interacts with app data | Natural fit | Requires mapping app context into Connect attributes |
| Human agent escalation | Must build or integrate separately | Strong built-in fit |
| Queues / routing / transcripts | Must build or integrate separately | Strong built-in fit |
| Long-term product ownership | Fully aligned with our roadmap | Coupled to Amazon Connect concepts |
| Complexity for our use case | Lower | Higher and indirect |
| Future support-center use | Add later if needed | Strong if support is the core problem |

## When Amazon Connect Would Be A Good Choice

If the main goal were:

- customer support chat
- routing to human agents
- bot-to-agent handoff
- queueing and transcript management
- contact-center operations

## Why In-House Is Better For Us

- We want users to interact with our app and our data, not a support-center backend first.
- We would still need to build our own backend logic anyway.
- Using Amazon Connect adds extra infrastructure and constraints without solving the core product problem.

## Suggested Decision Statement

We should build the chat experience in-house because our use case is a product interaction layer over internal app data, while Amazon Connect is primarily a contact-center chat platform. It would add backend and integration complexity without materially reducing the work required for our core experience.

## Balanced Note

Amazon Connect may still be useful later for escalation to support agents, but it is not the best foundation for the primary in-app chat experience.

## Sources

- [Amazon Connect Chat SDK for iOS README](https://github.com/amazon-connect/amazon-connect-chat-ios)
- [AWS mobile SDK announcement](https://aws.amazon.com/about-aws/whats-new/2024/10/amazon-connect-ios-android-sdks-chat-experiences/)
- [StartChatContact API](https://docs.aws.amazon.com/connect/latest/APIReference/API_StartChatContact.html)
- [CreateParticipantConnection API](https://docs.aws.amazon.com/connect/latest/APIReference/API_connect-participant_CreateParticipantConnection.html)
