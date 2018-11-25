//
//  AllAnyTree.swift
//  ScheduleOrganizer
//
//  Created by Lantua on 9/25/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

enum AllAnyTree<T>: Sequence {
    case all([AllAnyTree<T>])
    case any([AllAnyTree<T>])
    case entry(T)
    
    func makeIterator() -> AnyIterator<[T]> {
        switch self {
        case let .all(array): return AnyIterator(AllTreeIterator(array: array))
        case let .any(array): return AnyIterator(AnyTreeIterator(array: array))
        case let .entry(entry): return AnyIterator(IteratorOverOne(_elements: [entry]))
        }
    }
    
    var underestimatedCount: Int {
        switch self {
        case let .all(array): return array.lazy.map { $0.underestimatedCount } .reduce(1, *)
        case let .any(array): return array.lazy.map { $0.underestimatedCount } .reduce(0, +)
        case .entry: return 1
        }
    }
}

private struct AllTreeIterator<T>: IteratorProtocol {
    var sources: [AllAnyTree<T>]
    var iterators: [AllAnyTree<T>.Iterator]
    var values: [[T]]?
    
    init(array: [AllAnyTree<T>]) {
        sources = array
        iterators = sources.map { $0.makeIterator() }
        values = iterators.map { $0.next() } as? [[T]]
    }
    
    mutating func next() -> [T]? {
        guard let oldValues = values else { return nil }
        let result = oldValues.flatMap { $0 }
        
        var newValues = oldValues as [[T]?]
        
        for (index, iterator) in iterators.enumerated() {
            let next = iterator.next()
            newValues[index] = next
            if next != nil { break }
        }
        guard nil != newValues.last! else {
            values = nil
            return result
        }
        
        for index in 0..<iterators.count {
            guard newValues[index] == nil else { break }
            let newIterator = sources[index].makeIterator()
            iterators[index] = newIterator
            newValues[index] = newIterator.next()!
        }
        
        values = (newValues as! [[T]])
        return result
    }
}

private struct AnyTreeIterator<T>: IteratorProtocol {
    var major: Array<AllAnyTree<T>>.Iterator
    var minor: AllAnyTree<T>.Iterator?
    
    init(array: [AllAnyTree<T>]) {
        major = array.makeIterator()
        minor = major.next()?.makeIterator()
    }
    
    mutating func next() -> [T]? {
        if let next = minor?.next() {
            return next
        }
        minor = major.next()?.makeIterator()
        return minor?.next()
    }
}

extension AllAnyTree {
    mutating func clean() {
        if case .all(var data) = self {
            cleanSubentries(data: &data)
            
            guard data.count > 1 else {
                if data.isEmpty {
                    self = .any([])
                } else {
                    assert(data.count == 1)
                    self = data.first!
                }
                return
            }

            let pivot = data.partition {
                if case .all(_) = $0 {
                    return true
                }
                return false
            }
            let mergable = data[pivot...].flatMap { value -> [AllAnyTree] in
                guard case .all(let value) = value else {
                    fatalError()
                }
                return value
            }
            let unmergable = data[0..<pivot]
            self = .all(mergable + Array(unmergable))
        } else if case .any(var data) = self {
            cleanSubentries(data: &data)
            
            guard data.count > 1 else {
                if data.isEmpty {
                    self = .any([])
                } else {
                    assert(data.count == 1)
                    self = data.first!
                }
                return
            }
            
            let pivot = data.partition {
                if case .any(_) = $0 {
                    return true
                }
                return false
            }
            let mergable = data[pivot...].flatMap { value -> [AllAnyTree] in
                guard case .any(let value) = value else {
                    fatalError()
                }
                return value
            }
            let unmergable = data[0..<pivot]
            self = .any(mergable + Array(unmergable))
        }
    }
    
    private func cleanSubentries(data: inout [AllAnyTree]) {
        for i in 0..<data.count {
            data[i].clean()
        }
        data = data.filter {
            switch $0 {
            case .any(let data) where data.isEmpty,
                 .all(let data) where data.isEmpty:
                return false
            default: return true
            }
        }
    }
}
