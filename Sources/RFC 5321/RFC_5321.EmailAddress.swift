//
//  RFC_5321.EmailAddress.swift
//  swift-rfc-5321
//
//  EmailAddress implementation
//

import RegexBuilder
import Standards
import INCITS_4_1986
public import RFC_1123

extension RFC_5321 {
    /// RFC 5321 compliant email address (basic SMTP format)
    ///
    /// An email address consists of a local-part, @ sign, and domain.
    /// Optionally includes a display name in angle-bracket format.
    public struct EmailAddress: Hashable, Sendable {
        /// The display name, if present
        public let displayName: String?

        /// The local part (before @)
        public let localPart: LocalPart

        /// The domain part (after @)
        public let domain: RFC_1123.Domain

        /// Initialize with validated components
        ///
        /// This is the canonical initializer. Components are already validated.
        public init(displayName: (some StringProtocol)? = nil, localPart: LocalPart, domain: RFC_1123.Domain) throws(Error) {
            self.displayName = displayName.map { String($0).trimming(.ascii.whitespaces) }
            self.localPart = localPart
            self.domain = domain

            // Check total length
            let addressLength = localPart.value.count + 1 + domain.name.count  // +1 for @
            guard addressLength <= Limits.maxTotalLength else {
                throw Error.totalLengthExceeded(addressLength)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension RFC_5321.EmailAddress {
    /// Initialize from string representation ("Name <local@domain>" or "local@domain")
    ///
    /// Convenience initializer that parses and validates the email address.
    public init(_ string: some StringProtocol) throws(Error) {
        let stringValue = String(string)
        let displayNameCapture = /(?:((?:\"(?:[^\"\\]|\\.)*\"|[^<]+?))\s*)/
        let emailCapture = /<([^@]+)@([^>]+)>/

        let fullRegex = Regex {
            Optionally {
                displayNameCapture
            }
            emailCapture
        }

        // Try matching the full address format first (with angle brackets)
        if let match = try? fullRegex.wholeMatch(in: stringValue) {
            let captures = match.output

            // Extract display name if present and normalize spaces
            let displayName = captures.1.map { name in
                let trimmedName = name.trimming(.ascii.whitespaces)
                if trimmedName.hasPrefix("\"") && trimmedName.hasSuffix("\"") {
                    let withoutQuotes = String(trimmedName.dropFirst().dropLast())
                    return withoutQuotes.replacing("\\\"", with: "\"")
                        .replacing("\\\\", with: "\\")
                }
                return trimmedName
            }

            let localPartString = String(captures.2)
            let domainString = String(captures.3)

            // Validate and construct components with error wrapping
            let localPart: LocalPart
            do {
                localPart = try LocalPart(localPartString)
            } catch let localError {
                throw Error.invalidLocalPart(localError)
            }

            let domain: RFC_1123.Domain
            do {
                domain = try RFC_1123.Domain(domainString)
            } catch let domainError as Domain.ValidationError {
                throw Error.invalidDomain(domainError)
            } catch {
                fatalError("Unexpected error type from RFC_1123.Domain.init: \(error)")
            }

            try self.init(
                displayName: displayName as String?,
                localPart: localPart,
                domain: domain
            )
        } else {
            // Try parsing as bare email address
            guard let atIndex = stringValue.firstIndex(of: "@") else {
                throw Error.missingAtSign
            }

            let localString = String(stringValue[..<atIndex])
            let domainString = String(stringValue[stringValue.index(after: atIndex)...])

            // Validate and construct components with error wrapping
            let localPart: LocalPart
            do {
                localPart = try LocalPart(localString)
            } catch let localError {
                throw Error.invalidLocalPart(localError)
            }

            let domain: RFC_1123.Domain
            do {
                domain = try RFC_1123.Domain(domainString)
            } catch let domainError as Domain.ValidationError {
                throw Error.invalidDomain(domainError)
            } catch {
                fatalError("Unexpected error type from RFC_1123.Domain.init: \(error)")
            }

            try self.init(
                displayName: nil as String?,
                localPart: localPart,
                domain: domain
            )
        }
    }
}

// MARK: - Properties

extension RFC_5321.EmailAddress {
    /// The complete email address string, including display name if present
    public var value: String {
        String(self)
    }

    /// Just the email address part without display name
    public var address: String {
        "\(localPart)@\(domain.name)"
    }
}

// MARK: - Constants and Validation

extension RFC_5321.EmailAddress {
    internal enum Limits {
        static let maxTotalLength = 254  // Maximum total email address length
    }

    // Dot-atom regex: series of atoms separated by dots
    // RFC 5321 uses the atext definition from RFC 5322 Section 3.2.3
    // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
    nonisolated(unsafe) internal static let dotAtomRegex =
        /[a-zA-Z0-9!#$%&'*+\-\/=?\^_`{|}~]+(?:\.[a-zA-Z0-9!#$%&'*+\-\/=?\^_`{|}~]+)*/

    // Quoted string regex: allows any printable character except unescaped quotes
    nonisolated(unsafe) internal static let quotedRegex = /(?:[^"\\]|\\["\\])+/
}

// MARK: - Protocol Conformances

extension RFC_5321.EmailAddress: CustomStringConvertible {
    public var description: String { String(self) }
}

extension RFC_5321.EmailAddress: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }
}

extension RFC_5321.EmailAddress: RawRepresentable {
    public var rawValue: String { String(self) }
    public init?(rawValue: some StringProtocol) { try? self.init(rawValue) }
}
