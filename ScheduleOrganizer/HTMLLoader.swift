//
//  HTMLLoader.swift
//  ScheduleOrganizer
//
//  Created by Lantua on 9/25/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import Foundation

let calendar = Calendar(identifier: .gregorian)

func loadSlots(from url: String, courses: Set<String>) -> [SectionTimeSlot] {
    print("Loading")
    let content = try! String(contentsOf: URL(string: url)!)
    print("Parsing")
    return slots(from: content, courses: courses)
}

private func slots(from content: String, courses: Set<String>) -> [SectionTimeSlot] {
    return texts(inside: "tr", text: content).flatMap {
        row -> SectionTimeSlot? in
        parse(text: row, courses: courses)
    }
}

private func texts(inside innermostTag: String, text: String) -> [String] {
    let regex = try! NSRegularExpression(pattern: "<\(innermostTag)\\b[^>]*+>(.*?)</\(innermostTag)\\b", options: [.dotMatchesLineSeparators, .caseInsensitive])
    let utf16 = text.utf16
    
    return regex.matches(in: text, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: utf16.count)).flatMap {
        result -> String? in
        guard result.numberOfRanges == 2 else {
            return nil
        }
        let range = Range(result.range(at: 1))!
        let startIndex = String.UTF16Index(encodedOffset: range.lowerBound)
        let endIndex = String.UTF16Index(encodedOffset: range.upperBound)
        
        return String(utf16[startIndex..<endIndex])
    }
}

private func parse(text: String, courses: Set<String>) -> SectionTimeSlot? {
    let columns = texts(inside: "font", text: text)
    
    guard columns.count >= 8 else {
        return nil
    }
    
    let course = String(columns[0].prefix(upTo: (columns[0].index(columns[0].endIndex, offsetBy: -3))))
    guard courses.contains(course),
        let section = section(from: columns[1], course: course),
        let startDate = date(from: columns[2]),
        let startTime = minutes(from: columns[4]),
        let endTime = minutes(from: columns[5]) else {
            return nil
    }
    
    let day = DayOfWeek(abbreviation: columns[3]) ?? dayOfWeek(from: startDate)!
    let slot = TimeSlot(day: day, time: startTime..<endTime, alternation: alternation(from: columns[8], startDate: startDate))
    
    return (section, slot)
}

private func section(from text: String, course: CourseName) -> Section? {
    let splittingIndex = text.index(text.startIndex, offsetBy: 3)
    let prefix = text.prefix(upTo: splittingIndex)
    let suffix = text.suffix(from: splittingIndex)
    
    let category: Section.Category
    switch prefix {
    case "LEC": category = .lec
    case "TUT": category = .tut
    case "PRA": category = .pra
    default: return nil
    }
    
    return Section(courseName: course, category: category, sectionName: String(suffix))
}

private func dayOfWeek(from date: Date) -> DayOfWeek? {
    let dayOfWeek = calendar.component(.weekday, from: date)
    return DayOfWeek(rawValue: dayOfWeek)
}

private func minutes(from text: String) -> MinuteFromMidnight? {
    let components = text.components(separatedBy: ":")
    guard let hours = Int(components[0]),
        let minutes = Int(components[1]) else {
        return nil
    }
    assert(hours <= 24 && minutes < 60)
    
    return hours * 60 + minutes
}

private func date(from text: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy/MM/dd"
    formatter.calendar = calendar
    return formatter.date(from: text)
}

private func alternation(from note: String, startDate: Date) -> Alternation {
    let start, cycle: Int
    start = calendar.component(.weekOfYear, from: startDate)
    
    if let cycleNoteIndex = note.range(of: "occurs once every ")?.upperBound {
        let cycleSubstring = note.suffix(from: cycleNoteIndex)
        if cycleSubstring.hasPrefix("two weeks") {
            cycle = 2
        } else if cycleSubstring.hasPrefix("three weeks") {
            cycle = 3
        } else if cycleSubstring.hasPrefix("four weeks") {
            cycle = 4
        } else {
            fatalError("Unhandled Case")
        }
    } else {
        cycle = 1
    }
    
    return Alternation(start: start, cycle: cycle)
}
