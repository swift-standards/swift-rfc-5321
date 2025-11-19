import RegexBuilder
import Standards
import INCITS_4_1986

@_exported import struct RFC_1123.Domain

/// RFC 5321 compliant email address (basic SMTP format)
public struct EmailAddress: Hashable, Sendable {
    /// The display name, if present
    public let displayName: String?

    /// The local part (before @)
    public let localPart: LocalPart

    /// The domain part (after @)
    public let domain: RFC_1123.Domain

    /// Initialize with components
    public init(displayName: String? = nil, localPart: LocalPart, domain: RFC_1123.Domain) {
        self.displayName = displayName?.trimming(.whitespaces)
        self.localPart = localPart
        self.domain = domain
    }

    /// Initialize from string representation ("Name <local@domain>" or "local@domain")
    public init(_ string: String) throws {

        let displayNameCapture = /(?:((?:\"(?:[^\"\\]|\\.)*\"|[^<]+?))\s*)/

        let emailCapture = /<([^@]+)@([^>]+)>/

        let fullRegex = Regex {
            Optionally {
                displayNameCapture
            }
            emailCapture
        }

        // Try matching the full address format first (with angle brackets)
        if let match = try? fullRegex.wholeMatch(in: string) {
            let captures = match.output

            // Extract display name if present and normalize spaces
            let displayName = captures.1.map { name in
                let trimmedName = name.trimming(.whitespaces)
                if trimmedName.hasPrefix("\"") && trimmedName.hasSuffix("\"") {
                    let withoutQuotes = String(trimmedName.dropFirst().dropLast())
                    return withoutQuotes.replacing("\\\"", with: "\"")
                        .replacing("\\\\", with: "\\")
                }
                return trimmedName
            }

            let localPart = String(captures.2)
            let domain = String(captures.3)

            // Check total length before creating components
            let addressLength = localPart.count + 1 + domain.count  // +1 for @
            guard addressLength <= Limits.maxTotalLength else {
                throw ValidationError.totalLengthExceeded(addressLength)
            }

            try self.init(
                displayName: displayName,
                localPart: LocalPart(localPart),
                domain: .init(domain)
            )
        } else {
            // Try parsing as bare email address
            guard let atIndex = string.firstIndex(of: "@") else {
                throw ValidationError.missingAtSign
            }

            let localString = String(string[..<atIndex])
            let domainString = String(string[string.index(after: atIndex)...])

            try self.init(
                displayName: nil,
                localPart: LocalPart(localString),
                domain: .init(domainString)
            )
        }
    }
}

// MARK: - Local Part
extension RFC_5321.EmailAddress {
    /// RFC 5321 compliant local-part
    public struct LocalPart: Hashable, Sendable, CustomStringConvertible {
        private let storage: Storage

        /// Initialize with a string
        public init(_ string: String) throws {
            // RFC 5321 is ASCII-only - validate before processing
            guard string.asciiBytes != nil else {
                throw ValidationError.nonASCIICharacters
            }

            // Check overall length first
            guard string.count <= Limits.maxLength else {
                throw ValidationError.localPartTooLong(string.count)
            }

            // Handle quoted string format
            if string.hasPrefix("\"") && string.hasSuffix("\"") {
                let quoted = String(string.dropFirst().dropLast())
                guard (try? RFC_5321.EmailAddress.quotedRegex.wholeMatch(in: quoted)) != nil else {
                    throw ValidationError.invalidQuotedString
                }
                self.storage = .quoted(string)
            }
            // Handle dot-atom format
            else {
                guard (try? RFC_5321.EmailAddress.dotAtomRegex.wholeMatch(in: string)) != nil else {
                    throw ValidationError.invalidDotAtom
                }
                self.storage = .dotAtom(string)
            }
        }

        /// The string representation
        public var description: String {
            switch storage {
            case .dotAtom(let string), .quoted(let string):
                return string
            }
        }

        // swiftlint:disable:next nesting
        private enum Storage: Hashable {
            case dotAtom(String)  // Regular unquoted format
            case quoted(String)  // Quoted string format
        }
    }
}

// MARK: - Constants and Validation
extension RFC_5321.EmailAddress {
    private enum Limits {
        static let maxLength = 64  // Max length for local-part
        static let maxTotalLength = 254
    }

    // Dot-atom regex: series of atoms separated by dots
    // RFC 5321 uses the atext definition from RFC 5322 Section 3.2.3
    // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
    nonisolated(unsafe) private static let dotAtomRegex =
        /[a-zA-Z0-9!#$%&'*+\-\/=?\^_`{|}~]+(?:\.[a-zA-Z0-9!#$%&'*+\-\/=?\^_`{|}~]+)*/

    // Quoted string regex: allows any printable character except unescaped quotes
    nonisolated(unsafe) private static let quotedRegex = /(?:[^"\\]|\\["\\])+/
}

extension String {
    public init(
        _ email: RFC_5321.EmailAddress
    ) {
        if let name = email.displayName {
            let needsQuoting = name.contains(where: {
                !$0.isASCIILetter && !$0.isASCIIDigit && !$0.isASCIIWhitespace
            })
            let quotedName =
                needsQuoting ? "\"\(name.replacing("\"", with: "\\\""))\"" : name
            self = "\(quotedName) <\(email.localPart)@\(email.domain.name)>"  // Exactly one space before angle bracket
        } else {
            self = "\(email.localPart)@\(email.domain.name)"
        }
    }
}

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

// MARK: - Errors
extension RFC_5321.EmailAddress {
    public enum ValidationError: Error, Equatable {
        case missingAtSign
        case invalidDotAtom
        case invalidQuotedString
        case totalLengthExceeded(_ length: Int)
        case localPartTooLong(_ length: Int)
        case nonASCIICharacters

        public var errorDescription: String? {
            switch self {
            case .missingAtSign:
                return "Email address must contain @"
            case .invalidDotAtom:
                return "Invalid local-part format (before @)"
            case .invalidQuotedString:
                return "Invalid quoted string format in local-part"
            case .localPartTooLong(let length):
                return "Local-part length \(length) exceeds maximum of \(Limits.maxLength)"
            case .totalLengthExceeded(let length):
                return "Total length \(length) exceeds maximum of \(Limits.maxTotalLength)"
            case .nonASCIICharacters:
                return "RFC 5321 email addresses must contain only ASCII characters"
            }
        }
    }
}

// MARK: - Protocol Conformances
extension RFC_5321.EmailAddress: CustomStringConvertible {
    public var description: String { String(self) }
}

extension RFC_5321.EmailAddress: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue)
    }
}

extension RFC_5321.EmailAddress: RawRepresentable {
    public var rawValue: String { String(self) }
    public init?(rawValue: String) { try? self.init(rawValue) }
}
