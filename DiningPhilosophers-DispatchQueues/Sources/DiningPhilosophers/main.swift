//
//
//  Copyright (C) 2021 Thomas Kausch.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//
//  main.swift
//  SwiftConcurrency
//
//  Created by Thomas Kausch on 24.6.21.
//
//
// Layout of the table (P = philosopher, f = fork) for 4 Philosophers
//          P0
//       f3    f0
//     P3        P1
//       f2    f1
//          P2
//
//

import Dispatch

let NMB_OF_PHILOSOPHERS = 16

struct ForkPair {
    static let forks: [DispatchSemaphore] = Array(repeating: DispatchSemaphore(value: 0), count: NMB_OF_PHILOSOPHERS)

    let leftIdx: Int
    let rightIdx: Int
    
    
    init(left: Int, right: Int) {
        //Order forks by index to prevent deadlock
        if left > right {
            leftIdx = left
            rightIdx = right
        } else {
            leftIdx = right
            rightIdx = left
        }
    }
    
    static func enable() {
        //Start the thread signaling...
        for semaphore in ForkPair.forks {
            semaphore.signal()
        }
    }

    func pickUp() {
        //Acquire by starting with the lower index
        Self.forks[leftIdx].wait()
        Self.forks[rightIdx].wait()
    }

    func putDown() {
        //The order does not matter here
        Self.forks[rightIdx].signal()
        Self.forks[leftIdx].signal()
    }
}

struct Philosophers {
    let forkPair: ForkPair
    let index: Int

    init(index: Int) {
        let left = index
        var right = index - 1

        if right < 0 {
            right += NMB_OF_PHILOSOPHERS
        }

        self.forkPair = ForkPair(left: left, right: right)
        self.index = index

        print("Philosopher: \(index) created.")
    }

    func run() {
        while true {
            print("Philosopher: \(index) starts thinking")
            forkPair.pickUp()
            print("Philosopher: \(index) starts eating")
            sleep(UInt32(Int.random(in: 1..<5)))
            forkPair.putDown()
        }
    }
}

let globalSem = DispatchSemaphore(value: 0)


// Start philosophers
for i in 0..<NMB_OF_PHILOSOPHERS {
    if #available(macOS 10.10, *) {
        DispatchQueue.global(qos: .background).async {
            let p = Philosophers(index: i)
            p.run()
        }
    }
}

// Enable forks
ForkPair.enable()

//Wait forever
globalSem.wait()
