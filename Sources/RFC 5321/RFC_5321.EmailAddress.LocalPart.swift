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
    ///
    /// ## Constraints
    ///
    /// Per RFC 5321 Section 4.5.3.1.1:
    /// - Maximum length: 64 octets
    /// - Must be ASCII-only
    /// - Supports dot-atom or quoted-string format
    ///
    /// ## Example
    ///
    /// ```swift
    /// let localPart = try RFC_5321.EmailAddress.LocalPart(ascii: "user".utf8)
    /// ```
    public struct LocalPart: Hashable, Sendable, Codable {
        /// Canonical byte storage (ASCII-only per RFC 5321)
        let _value: [UInt8]

        /// The storage format (dot-atom or quoted)
        private let format: Format

        /// Raw string value
        public var rawValue: String {
            String(decoding: _value, as: UTF8.self)
        }

        /// String representation derived from canonical bytes
        public var value: String {
            String(ascii: self)
        }

        /// Creates local-part WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC validation. Only use for:
        /// - Static constants
        /// - Pre-validated values
        /// - Internal construction after validation
        init(__unchecked: Void, rawValue: String) {
            self._value = [UInt8](utf8: rawValue)
            // Infer format from presence of quotes
            if rawValue.hasPrefix("\"") && rawValue.hasSuffix("\"") {
                self.format = .quoted
            } else {
                self.format = .dotAtom
            }
        }

        /// Initialize a local-part from a string, validating RFC 5321 rules
        ///
        /// This is a convenience initializer that converts String to bytes.
        public init(_ string: some StringProtocol) throws(Error) {
            try self.init(ascii: Array(string.utf8))
        }

        // MARK: - Format

        private enum Format: Hashable, Codable {
            case dotAtom     // Regular unquoted format
            case quoted      // Quoted string format
        }
    }
}

// MARK: - Byte-Level Parsing (UInt8.ASCII.Serializable)

extension RFC_5321.EmailAddress.LocalPart: UInt8.ASCII.Serializable {
    /// Initialize from ASCII bytes, validating RFC 5321 rules
    ///
    /// ## Category Theory
    ///
    /// Parsing transformation:
    /// - **Domain**: [UInt8] (ASCII bytes)
    /// - **Codomain**: RFC_5321.EmailAddress.LocalPart (structured data)
    ///
    /// String parsing is derived composition:
    /// ```
    /// String → [UInt8] (UTF-8) → LocalPart
    /// ```
    ///
    /// ## Constraints
    ///
    /// Per RFC 5321 Section 4.5.3.1.1:
    /// - Must be ASCII-only
    /// - Maximum 64 octets
    /// - Supports dot-atom or quoted-string format
    ///
    /// ## Example
    ///
    /// ```swift
    /// let localPart = try RFC_5321.EmailAddress.LocalPart(ascii: "user".utf8)
    /// ```
    public init<Bytes: Collection>(ascii bytes: Bytes, in _: Void = ()) throws(Error)
    where Bytes.Element == UInt8 {
        guard let firstByte = bytes.first else { throw Error.empty }

        var count = 0
        var lastByte = firstByte
        for byte in bytes {
            count += 1
            lastByte = byte
            // Validate ASCII-only (high bit must be 0)
            guard byte < 0x80 else {
                throw Error.nonASCII
            }
        }

        guard count <= Limits.maxLength else {
            throw Error.tooLong(count)
        }

        let rawValue = String(decoding: bytes, as: UTF8.self)

        // Handle quoted string format
        if firstByte == .ascii.quotationMark {
            guard lastByte == .ascii.quotationMark else {
                throw Error.invalidQuotedString(rawValue)
            }

            // Validate quoted string content
            var insideQuotes = false
            var escaped = false
            for byte in bytes {
                if !insideQuotes {
                    if byte == .ascii.quotationMark {
                        insideQuotes = true
                    }
                } else {
                    if escaped {
                        escaped = false
                        // After backslash, allow quote or backslash
                        guard byte == .ascii.quotationMark || byte == .ascii.reverseSolidus else {
                            throw Error.invalidQuotedString(rawValue)
                        }
                    } else if byte == .ascii.reverseSolidus {
                        escaped = true
                    } else if byte == .ascii.quotationMark {
                        // End of quoted string
                        break
                    } else {
                        // Inside quotes: allow printable ASCII except unescaped quote
                        guard byte >= 0x20 && byte < 0x7F else {
                            throw Error.invalidCharacter(rawValue, byte: byte)
                        }
                    }
                }
            }

            self._value = Array(bytes)
            self.format = .quoted
        }
        // Handle dot-atom format
        else {
            // atext = ALPHA / DIGIT / "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "/" / "=" / "?" / "^" / "_" / "`" / "{" / "|" / "}" / "~"
            var lastWasDot = false
            var index = bytes.startIndex

            for byte in bytes {
                let isAtext = byte.ascii.isLetter || byte.ascii.isDigit ||
                    byte == 0x21 || // !
                    byte == 0x23 || // #
                    byte == 0x24 || // $
                    byte == 0x25 || // %
                    byte == 0x26 || // &
                    byte == 0x27 || // '
                    byte == 0x2A || // *
                    byte == 0x2B || // +
                    byte == 0x2D || // -
                    byte == 0x2F || // /
                    byte == 0x3D || // =
                    byte == 0x3F || // ?
                    byte == 0x5E || // ^
                    byte == 0x5F || // _
                    byte == 0x60 || // `
                    byte == 0x7B || // {
                    byte == 0x7C || // |
                    byte == 0x7D || // }
                    byte == 0x7E    // ~

                let isDot = byte == .ascii.period

                guard isAtext || isDot else {
                    throw Error.invalidCharacter(rawValue, byte: byte)
                }

                // Can't start or end with dot, can't have consecutive dots
                if isDot {
                    guard index != bytes.startIndex else {
                        throw Error.invalidDotAtom(rawValue)
                    }
                    guard !lastWasDot else {
                        throw Error.invalidDotAtom(rawValue)
                    }
                }

                lastWasDot = isDot
                index = bytes.index(after: index)
            }

            // Can't end with dot
            guard !lastWasDot else {
                throw Error.invalidDotAtom(rawValue)
            }

            self._value = Array(bytes)
            self.format = .dotAtom
        }
    }
}

// MARK: - Protocol Conformances

extension RFC_5321.EmailAddress.LocalPart: UInt8.ASCII.RawRepresentable {
    public typealias RawValue = String
}

// MARK: - ASCII Serialization

extension RFC_5321.EmailAddress.LocalPart {
    /// Serialize local-part to ASCII bytes
    ///
    /// Required implementation for `UInt8.ASCII.RawRepresentable` to avoid
    /// infinite recursion (since `rawValue` is synthesized from serialization).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        ascii localPart: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == UInt8 {
        buffer.append(contentsOf: localPart._value)
    }
}

extension RFC_5321.EmailAddress.LocalPart: CustomStringConvertible {
    public var description: String {
        String(decoding: _value, as: UTF8.self)
    }
}

// MARK: - Constants

extension RFC_5321.EmailAddress.LocalPart {
    package enum Limits {
        static let maxLength = 64  // Max length for local-part per RFC 5321
    }
}
