//
//  Enumeration.swift
//  ScheduleOrganizer
//
//  Created by Lantua on 9/25/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

enum Enumeration<T>: Sequence {
    case all([Enumeration<T>])
    case any([Enumeration<T>])
    case entry(T)
    
    func makeIterator() -> AnyIterator<[T]> {
        switch self {
        case let .all(array): return AnyIterator(EnumerationAllIterator(array: array))
        case let .any(array): return AnyIterator(EnumerationAnyIterator(array: array))
        case let .entry(entry): return AnyIterator(IteratorOverOne(_elements: [entry]))
        }
    }
    
    var underestimatedCount: Int {
        switch self {
        case let .all(array): return array.map({ $0.underestimatedCount }).reduce(1, *)
        case let .any(array): return array.map({ $0.underestimatedCount }).reduce(0, +)
        case .entry: return 1
        }
    }
}

private struct EnumerationAllIterator<T>: IteratorProtocol {
    var sources: [Enumeration<T>]
    var iterators: [Enumeration<T>.Iterator]
    var values: [[T]]?
    
    init(array: [Enumeration<T>]) {
        sources = array
        iterators = sources.map { $0.makeIterator() }
        let tempValues = iterators.map { $0.next() }
        if tempValues.contains(where: { $0 == nil }) {
            values = nil
        } else {
            values = tempValues.map { $0! }
        }
    }
    
    mutating func next() -> [T]? {
        guard let oldValues = values else { return nil }
        let result = oldValues.flatMap { $0 }
        
        var newValues = oldValues as [[T]?]
        
        for (index, iterator) in iterators.enumerated().reversed() {
            let next = iterator.next()
            newValues[index] = next
            if next != nil { break }
        }
        guard let first = newValues.first, first != nil else {
            values = nil
            return result
        }
        
        for index in (0..<iterators.count).reversed() {
            guard newValues[index] == nil else { break }
            iterators[index] = sources[index].makeIterator()
            newValues[index] = iterators[index].next()!
        }
        
        values = (newValues as! [[T]])
        return result
    }
}

private struct EnumerationAnyIterator<T>: IteratorProtocol {
    var majorIterator: Array<Enumeration<T>>.Iterator
    var minorIterator: Enumeration<T>.Iterator?
    
    init(array: [Enumeration<T>]) {
        majorIterator = array.makeIterator()
        minorIterator = majorIterator.next()?.makeIterator()
    }
    
    mutating func next() -> [T]? {
        if let next = minorIterator?.next() {
            return next
        }
        minorIterator = majorIterator.next()?.makeIterator()
        return minorIterator?.next()
    }
}
