//
//  ReadmeVerificationTests.swift
//  swift-rfc-5321
//
//  Verifies that README code examples actually work
//

import RFC_5321
import Testing

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("README Line 52-55: Parse simple email address")
    func parseSimpleEmailAddress() throws {
        let email = try EmailAddress("user@example.com")
        #expect(email.localPart.description == "user")
        #expect(email.domain.name == "example.com")
    }

    @Test("README Line 57-60: Parse with display name")
    func parseWithDisplayName() throws {
        let namedEmail = try EmailAddress("John Doe <john@example.com>")
        #expect(namedEmail.displayName == "John Doe")
        #expect(namedEmail.address == "john@example.com")
    }

    @Test("README Line 62-64: Parse with quoted display name")
    func parseWithQuotedDisplayName() throws {
        let quotedEmail = try EmailAddress("\"Doe, John\" <john@example.com>")
        #expect(quotedEmail.displayName == "Doe, John")
    }

    @Test("README Line 70-80: Create from components")
    func createFromComponents() throws {
        let localPart = try EmailAddress.LocalPart("support")
        let domain = try Domain("example.com")
        let email = EmailAddress(
            displayName: "Support Team",
            localPart: localPart,
            domain: domain
        )

        #expect(email.description == "Support Team <support@example.com>")
        #expect(email.address == "support@example.com")
    }

    @Test("README Line 86-89: Valid addresses")
    func validAddresses() throws {
        let valid1 = try EmailAddress("simple@example.com")
        let valid2 = try EmailAddress("user.name@example.com")
        let valid3 = try EmailAddress("\"user name\"@example.com")

        #expect(valid1.localPart.description == "simple")
        #expect(valid2.localPart.description == "user.name")
        #expect(valid3.localPart.description == "\"user name\"")
    }

    @Test("README Line 91-96: Invalid address throws missing at sign")
    func invalidAddressMissingAtSign() throws {
        #expect(throws: EmailAddress.ValidationError.missingAtSign) {
            _ = try EmailAddress("no-at-sign")
        }
    }

    @Test("README Line 98-102: Invalid address local part too long")
    func invalidAddressLocalPartTooLong() throws {
        let longAddress =
            "verylonglocalpartthatexceedssixtyfourcharactersshouldnotbeallowed@example.com"
        #expect(throws: EmailAddress.ValidationError.self) {
            _ = try EmailAddress(longAddress)
        }
    }

    @Test("README Line 145: Domain usage")
    func domainUsage() throws {
        let domain = try Domain("mail.example.com")
        #expect(domain.name == "mail.example.com")
    }
}
