//
//  CourseClassification.swift
//  ScheduleOrganizer
//
//  Created by Lantua on 9/25/2560 BE.
//  Copyright © 2560 Lantua. All rights reserved.
//

func enumerations(for slots: [SectionTimeSlot]) -> [CourseName: Enumeration<SectionTimeSlot>] {
    let slotsByCourse = Dictionary(grouping: slots) { $0.section.courseName }
    return slotsByCourse.mapValues(classEnumeration)
}

// Enumeration assuming every slot is in the same class
private func classEnumeration(for slots: [SectionTimeSlot]) -> Enumeration<SectionTimeSlot> {
    let slotsByCategory = Dictionary(grouping: slots, by: { $0.section.category }).values
    let categories = slotsByCategory.map(categoryEnumeration)
    return .all(categories)
}

// Enumeration assuming every slot is in the same class and category (lec, tut, pra)
private func categoryEnumeration(for slots: [SectionTimeSlot]) -> Enumeration<SectionTimeSlot> {
    let slotsBySection = Dictionary(grouping: slots, by: { $0.section }).values
    let sections = slotsBySection.map { Enumeration.all($0.map { .entry($0) }) }
    return .any(sections)
}
