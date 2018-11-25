//
//  CourseClassification.swift
//  ScheduleOrganizer
//
//  Created by Lantua on 9/25/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

private struct Category: Hashable {
    var courseName: CourseName
    var category: Section.Category
    
    init(section: Section) {
        courseName = section.courseName
        category = section.category
    }
}

func enumerations(for slots: [SectionTimeSlot]) -> [CourseName: AllAnyTree<SectionTimeSlot>] {
    let dataBySection = Dictionary(grouping: slots) { $0.section } .mapValues {
        // All timeslot of the same section are together
        AllAnyTree.all($0.map { AllAnyTree.entry($0) })
    }
    let dataByCategory = Dictionary(grouping: dataBySection) { Category(section: $0.key) } .mapValues {
        // One can choose between section in the same category
        AllAnyTree.any($0.map { $0.value })
    }
    let dataByCourse = Dictionary(grouping: dataByCategory) { $0.key.courseName } .mapValues {
        // One must choose lecture, tutorial AND practice session
        AllAnyTree.all($0.map { $0.value })
    }
    return dataByCourse
}
