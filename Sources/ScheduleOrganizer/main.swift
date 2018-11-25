//
//  main.swift
//  ScheduleOrganizer
//
//  Created by Lantua on 9/25/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

import Foundation

let courses: Set<String> = [ "ECE472", "ECE461" ]
let url = "https://portal.engineering.utoronto.ca/sites/timetable/fall.html"

let slots = loadSlots(from: url, courses: courses)
print("Calculating")

let enums = enumerations(for: slots)
let courseEnums = AllAnyTree.all(courses.map { enums[$0]! })

var result: (Double, [[SectionTimeSlot]]) = (Double.infinity, [])
let (collision, selections) = courseEnums.reduce(into: result) {
    (result, slots) in
    let threshold = result.0
    var collision = 0.0
    for (pivot, slot1) in slots.enumerated() {
        for slot2 in slots[..<pivot] where slot1.section != slot2.section {
            collision += collidingMinutes(slot1.slot, slot2.slot)
            if collision > threshold { return }
        }
    }
    if collision < threshold {
        result = (collision, [slots])
    } else if collision == threshold {
        result.1.append(slots)
    }
}

for (i, selection) in selections.enumerated() {
    print("\(i)")
    for value in Set(selection.map { $0.section }).sorted(by: { $0.courseName < $1.courseName }) {
        print(value)
    }
    print()
}

print("Out of \(courseEnums.underestimatedCount) scheduling ways, there are \(selections.count) ways with \(collision) hours of collision")
