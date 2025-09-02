//
//  Type.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

enum Type: String, CaseIterable {
    case string = "String"
    case int = "Int"
    case int64 = "Int64"
    case double = "Double"
    case float = "Float"
    case uuid = "UUID"
    case date = "Date"
    case url = "URL"
    case data = "Data"
    case nsError = "NSError"
    case decimal = "Decimal"
    case timeInterval = "TimeInterval"
    case bool = "Bool"

    /// Type can be `static`, `dynamic`, or `arbitrary`.
    func isDynamicOrStatic() -> Bool {
        [Type.string, Type.int, Type.int64, Type.double, Type.float, Type.date, Type.decimal, Type.timeInterval, Type.bool]
            .contains(self)
    }
}
