//
//  RFC_5321.EmailAddress.LocalPart.swift
//  swift-rfc-5321
//
//  LocalPart implementation with canonical byte storage
//

import Standards
import INCITS_4_1986

extension RFC_5321.EmailAddress {
    /// RFC 5321 compliant local-part
    ///
    /// The local-part appears before the @ sign in an email address.
    /// RFC 5321 supports two formats: dot-atom and quoted-string.
    public struct LocalPart: Hashable, Sendable {
        /// Canonical byte storage (ASCII-only per RFC 5321)
        let _value: [UInt8]

        /// The storage format (dot-atom or quoted)
        private let format: Format

        /// String representation derived from canonical bytes
        public var value: String {
            String(self)
        }

        /// Initialize a local-part from a string, validating RFC 5321 rules
        ///
        /// This is the canonical initializer that performs validation.
        public init(_ string: String) throws(Error) {
            // Check emptiness
            guard !string.isEmpty else {
                throw Error.empty
            }

            // RFC 5321 is ASCII-only - validate before processing
            guard string.allSatisfy({ $0.isASCII }) else {
                throw Error.nonASCII
            }

            // Check overall length
            guard string.count <= Limits.maxLength else {
                throw Error.tooLong(string.count)
            }

            // Handle quoted string format
            if string.hasPrefix("\"") && string.hasSuffix("\"") {
                let quoted = String(string.dropFirst().dropLast())
                guard (try? RFC_5321.EmailAddress.quotedRegex.wholeMatch(in: quoted)) != nil else {
                    throw Error.invalidQuotedString(string)
                }
                self.format = .quoted
                self._value = [UInt8](utf8: string)
            }
            // Handle dot-atom format
            else {
                guard (try? RFC_5321.EmailAddress.dotAtomRegex.wholeMatch(in: string)) != nil else {
                    throw Error.invalidDotAtom(string)
                }
                self.format = .dotAtom
                self._value = [UInt8](utf8: string)
            }
        }

        // MARK: - Format

        private enum Format: Hashable {
            case dotAtom     // Regular unquoted format
            case quoted      // Quoted string format
        }
    }
}

// MARK: - Convenience Initializers

extension RFC_5321.EmailAddress.LocalPart {
    /// Initialize a local-part from bytes, validating RFC 5321 rules
    ///
    /// Convenience initializer that decodes bytes as UTF-8 and validates.
    public init(_ bytes: [UInt8]) throws(Error) {
        let string = String(decoding: bytes, as: UTF8.self)
        try self.init(string)
    }
}

// MARK: - Constants

extension RFC_5321.EmailAddress.LocalPart {
    private enum Limits {
        static let maxLength = 64  // Max length for local-part per RFC 5321
    }
}

// MARK: - Protocol Conformances

extension RFC_5321.EmailAddress.LocalPart: CustomStringConvertible {
    public var description: String {
        String(decoding: _value, as: UTF8.self)
    }
}
