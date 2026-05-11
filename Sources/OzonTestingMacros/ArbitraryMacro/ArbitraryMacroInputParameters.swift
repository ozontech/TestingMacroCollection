//
//  ArbitraryMacroInputParameters.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

struct ArbitraryMacroInputParameters {
    private enum AccessModifier: String {
        case auto
        case `public`
        case `internal`

        var modifierDecl: DeclModifierSyntax? {
            switch self {
            case .public:
                .init(name: .keyword(.public))
            case .internal:
                .init(name: .keyword(.internal))
            case .auto:
                nil
            }
        }
    }

    var accessModifier: DeclModifierSyntax {
        if let am = _accessModifier.modifierDecl {
            return am
        }

        return declGroup.accessModifier
    }

    var arbitraryConfig: ArbitraryMacro.ArbitraryConfig {
        _arbitraryConfig
    }

    let buildType: BuildType

    private let _arbitraryConfig: ArbitraryMacro.ArbitraryConfig
    private let _accessModifier: AccessModifier
    private let declGroup: DeclGroupSyntax

    init(node: AttributeSyntax, declGroup: DeclGroupSyntax) {
        self.declGroup = declGroup

        let parametersFromMacro = MacroArgumentExtracter.extractArguments(from: node)

        if let arbitraryType = parametersFromMacro[.unlabeledParam] as? String {
            _arbitraryConfig = ArbitraryMacro.ArbitraryConfig(rawValue: arbitraryType) ?? .static
        } else {
            _arbitraryConfig = .static
        }

        if let accessModifier = parametersFromMacro[.accessModifier] as? String {
            _accessModifier = AccessModifier(rawValue: accessModifier) ?? .auto
        } else {
            _accessModifier = .auto
        }

        if let buildTypeValue = parametersFromMacro[.buildType] as? String {
            buildType = BuildType(rawValue: buildTypeValue) ?? .debug
        } else {
            buildType = .debug
        }
    }
}
