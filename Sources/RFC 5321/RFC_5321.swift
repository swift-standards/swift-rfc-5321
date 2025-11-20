//
//  RFC_5321.swift
//  swift-rfc-5321
//
//  Created by Coen ten Thije Boonkkamp on 28/12/2024.
//

// Re-export RFC_1123.Domain for convenience
// RFC 5321 doesn't define its own domain syntax; it uses RFC 1123
@_exported import struct RFC_1123.Domain

public enum RFC_5321 {}
