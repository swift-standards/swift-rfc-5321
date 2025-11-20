// ===----------------------------------------------------------------------===//
//
// Copyright (c) 2025 Coen ten Thije Boonkkamp
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of project contributors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

// String+RFC_5321.swift
// swift-rfc-5321
//
// String representations composed through canonical byte serialization

import INCITS_4_1986
import Standards
public import RFC_1123

// MARK: - LocalPart String Representation

extension String {
    /// Creates string representation of an RFC 5321 local-part using UTF-8 encoding
    ///
    /// This is the canonical string representation that composes through bytes.
    ///
    /// ## Category Theory
    ///
    /// This is functor composition through the canonical byte representation:
    /// ```
    /// LocalPart → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ASCII is a subset of UTF-8, so this conversion is always safe.
    ///
    /// - Parameter localPart: The local-part to represent
    public init(_ localPart: RFC_5321.EmailAddress.LocalPart) {
        self.init(decoding: [UInt8](localPart), as: UTF8.self)
    }

    /// Creates string representation of an RFC 5321 local-part using a custom encoding
    ///
    /// Use this initializer when you need to decode the local-part bytes with a specific
    /// encoding other than UTF-8.
    ///
    /// - Parameters:
    ///   - localPart: The local-part to represent
    ///   - encoding: The Unicode encoding to use for decoding
    public init<Encoding>(_ localPart: RFC_5321.EmailAddress.LocalPart, as encoding: Encoding.Type)
        where Encoding: _UnicodeEncoding, Encoding.CodeUnit == UInt8 {
        self = String(decoding: [UInt8](localPart), as: encoding)
    }
}

// MARK: - EmailAddress String Representation

extension String {
    /// Creates string representation of an RFC 5321 email address
    ///
    /// This is the canonical string representation that composes through bytes.
    ///
    /// ## Category Theory
    ///
    /// This is functor composition:
    /// ```
    /// EmailAddress → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// - Parameter email: The email address to represent
    public init(_ email: RFC_5321.EmailAddress) {
        if let name = email.displayName {
            let needsQuoting = name.contains(where: {
                !$0.isASCIILetter && !$0.isASCIIDigit && !$0.isASCIIWhitespace
            })
            let quotedName = needsQuoting ? "\"\(name.replacing("\"", with: "\\\""))\"" : name
            self = "\(quotedName) <\(email.localPart)@\(email.domain.name)>"
        } else {
            self = "\(email.localPart)@\(email.domain.name)"
        }
    }

    /// Creates string representation of an RFC 5321 email address using a custom encoding
    ///
    /// - Parameters:
    ///   - email: The email address to represent
    ///   - encoding: The Unicode encoding to use for decoding
    public init<Encoding>(_ email: RFC_5321.EmailAddress, as encoding: Encoding.Type)
        where Encoding: _UnicodeEncoding, Encoding.CodeUnit == UInt8 {
        self = String(decoding: [UInt8](email), as: encoding)
    }
}
