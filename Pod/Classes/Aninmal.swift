//
//  Aninmal.swift
//  Animal
//
//  Created by bel on 2021/11/13.
//

import Foundation
open class Animal: NSObject {
    public func beginRun()  {
        print("开始跑步")
    }
    
    public func monkeyRun(){
        let monkey = Monkey()
        monkey.run()
    }
}
