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

// [UInt8]+RFC_5321.swift
// swift-rfc-5321
//
// Canonical byte serialization for RFC 5321 email addresses

import INCITS_4_1986
import Standards

// MARK: - LocalPart Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 5321 local-part
    ///
    /// This is the canonical serialization of local-part to bytes.
    /// RFC 5321 local-parts are ASCII-only by definition.
    ///
    /// ## Category Theory
    ///
    /// This is the most universal serialization (natural transformation):
    /// - **Domain**: RFC_5321.EmailAddress.LocalPart (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// LocalPart → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// ## Performance
    ///
    /// Zero-cost: Returns internal canonical byte storage directly.
    ///
    /// - Parameter localPart: The local-part to serialize
    public init(_ localPart: RFC_5321.EmailAddress.LocalPart) {
        // Zero-cost: direct access to canonical byte storage
        self = localPart._value
    }
}

// MARK: - EmailAddress Serialization

extension [UInt8] {
    /// Creates ASCII byte representation of an RFC 5321 email address
    ///
    /// The format is: [display-name] <local-part@domain>
    /// or just: local-part@domain
    ///
    /// ## Category Theory
    ///
    /// This is the canonical serialization (natural transformation):
    /// - **Domain**: RFC_5321.EmailAddress (structured data)
    /// - **Codomain**: [UInt8] (ASCII bytes)
    ///
    /// String representation is derived as composition:
    /// ```
    /// EmailAddress → [UInt8] (ASCII) → String (UTF-8 interpretation)
    /// ```
    ///
    /// - Parameter email: The email address to serialize
    public init(_ email: RFC_5321.EmailAddress) {
        let stringValue = String(email)
        self = [UInt8](utf8: stringValue)
    }
}
