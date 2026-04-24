//
//  Trivia+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension Trivia {
    static var ifDebug: Trivia {
        [.unexpectedText("#if DEBUG\n")]
    }

    static var endif: Trivia {
        [.unexpectedText("\n#endif")]
    }

    func ifNeeded(_ flag: Bool) -> Trivia? {
        flag ? self : nil
    }
}
