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

enum DayOfWeek: String {
    case sunday = "Sun", monday = "Mon", tuesday = "Tue", wednesday = "Wed", thursday = "Thu", friday = "Fri", saturday = "Sat"
}

struct Alternation {
    let start, cycle: Int
    
    init(start: Int, cycle: Int) {
        assert(cycle > 0)
        self.start = start % cycle
        self.cycle = cycle
    }
}

struct Section: CustomStringConvertible {
    enum Category { case lec, tut, pra }
    
    var courseName: CourseName
    var category: Category
    var sectionName: SectionName
    
    var description: String {
        return courseName + " " + String(describing: category) + sectionName
    }
}

struct TimeSlot {
    let day: DayOfWeek
    let time: Range<MinuteFromMidnight>
    let alternation: Alternation
    
    init(day: DayOfWeek, time: Range<MinuteFromMidnight>, alternation: Alternation) {
        self.day = day
        self.time = time.clamped(to: Range(0..<(24*60)))
        self.alternation = alternation
    }
}

func collidingMinutes(_ slot1: TimeSlot, _ slot2: TimeSlot) -> Double {
    guard slot1.day == slot2.day else { return 0 }
    
    let intersectedRange = slot1.time.clamped(to: slot2.time)
    let collisionChance = chanceOfCollision(slot1.alternation, slot2.alternation)
    
    return Double(intersectedRange.upperBound - intersectedRange.lowerBound) * collisionChance
}

private func GCD(_ lhs: Int, _ rhs: Int) -> Int {
    if rhs == 0 { return lhs }
    return GCD(rhs, lhs % rhs)
}

private func chanceOfCollision(_ lhs: Alternation, _ rhs: Alternation) -> Double {
    if lhs.cycle == rhs.cycle {
        return ((lhs.start - rhs.start) % rhs.cycle == 0) ? 1 : 0
    }
    return 1 / Double(lhs.cycle / GCD(lhs.cycle, rhs.cycle) * rhs.cycle)
}

extension Section: Hashable {
    static func ==(lhs: Section, rhs: Section) -> Bool {
        return lhs.courseName == rhs.courseName && lhs.category == rhs.category && lhs.sectionName == rhs.sectionName
    }
    var hashValue: Int { return courseName.hashValue ^ category.hashValue ^ sectionName.hashValue }
}
