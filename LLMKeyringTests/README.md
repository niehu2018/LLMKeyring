# LLMKeyringTests

This folder scaffolds a future XCTest target.

To enable tests in Xcode:
- Open `LLMKeyring/LLMKeyring.xcodeproj`.
- File > New > Target… > macOS > Test > Unit Testing Bundle.
- Name: `LLMKeyringTests`, set the app target as the Host Application (optional), and finish.
- Add `LLMKeyringTests/` files to the new test target (Target Membership in the File Inspector).

Run tests:
- Xcode: Product > Test (⌘U)
- CLI: `xcodebuild -project LLMKeyring/LLMKeyring.xcodeproj -scheme LLMKeyring -destination 'platform=macOS' test`

