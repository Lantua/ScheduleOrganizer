//
//  Courses.swift
//  ScheduleOrganizer
//
//  Created by Lantua on 9/25/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

typealias CourseName = String
typealias SectionName = String
typealias MinuteFromMidnight = Int
typealias SectionTimeSlot = (section: Section, slot: TimeSlot)

enum DayOfWeek: Int {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday
    
    init?(abbreviation: String) {
        switch abbreviation {
        case "Sun": self = .sunday
        case "Mon": self = .monday
        case "Tue": self = .tuesday
        case "Wed": self = .wednesday
        case "Thu": self = .thursday
        case "Fri": self = .friday
        case "Sat": self = .saturday
        default: return nil
        }
    }
}

struct Alternation: Hashable {
    let start, cycle: Int
    
    init(start: Int, cycle: Int) {
        assert(cycle > 0)
        self.start = start % cycle
        self.cycle = cycle
    }
}

struct Section: CustomStringConvertible, Hashable {
    enum Category: Hashable { case lec, tut, pra }
    
    var courseName: CourseName
    var category: Category
    var sectionName: SectionName
    
    var description: String {
        return courseName + " " + String(describing: category) + sectionName
    }
}

struct TimeSlot: Hashable {
    var alternation: Alternation
    var minutesFromMondayMidnight: Range<Int>

    init(day: DayOfWeek, time: Range<MinuteFromMidnight>, alternation: Alternation) {
        let minutesPerDay = 24 * 60
        let offset = day.rawValue * minutesPerDay
        minutesFromMondayMidnight = (offset + time.startIndex)..<(offset + time.endIndex)
        self.alternation = alternation
    }

}

func collidingMinutes(_ slot1: TimeSlot, _ slot2: TimeSlot) -> Double {
    let commonTime = slot1.minutesFromMondayMidnight.clamped(to: slot2.minutesFromMondayMidnight)
    
    return Double(commonTime.count) * chanceOfCollision(slot1.alternation, slot2.alternation)
}

private func chanceOfCollision(_ lhs: Alternation, _ rhs: Alternation) -> Double {
    if lhs.cycle == rhs.cycle {
        return lhs.start == rhs.start ? 1 : 0
    }
    return 1 / Double(lhs.cycle / GCD(lhs.cycle, rhs.cycle) * rhs.cycle)
}
private func GCD(_ lhs: Int, _ rhs: Int) -> Int {
    if rhs == 0 { return lhs }
    return GCD(rhs, lhs % rhs)
}
