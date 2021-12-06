//
//  model.swift
//  jupiter
//
//  Created by Sinaan Younus on 11/26/21.
//

import Foundation
import SwiftUI
import EventKit

// We need to declare structs that match the API response (so that we can store JSON)

// First, umd.io (https://api.umd.io/v1). We use this API in two ways.

// 1: /courses/<course_id>
// This gives us a host of data points on <course_id>, but it's most important functions are 1) letting us know if it's actually a real class (no 404 response) and 2) showing us what sections are being offered for the class

struct CourseResponse : Codable {
    let course_id : String
    let semester : String
    let name : String
    let dept_id : String
    let department : String
    let credits : String
    let description : String
    let grading_method : [String]
    let gen_ed : [[String]]
    let core : [String]
    let relationships : Relationships
    let sections : [String]
}

struct Relationships : Codable {
    // these all could be null so we have to declare them as optionals
    let coreqs : String?
    let prereqs : String?
    let formerly : String?
    let restrictions : String?
    let additional_info : String?
    let also_offered_as : String?
    let credit_granted_for : String?
}

// 2: /courses/sections/<section_id>
// The first API call (/courses/<course_id>) gives us access to an array called "sections". Each entry of this array is a diff section_id that we can pass into this API call, which gives us times, profs, etc -- all material we need to build the schedule

struct SectionResponse : Codable {
    let course : String
    let section_id : String
    let semester : String
    let number : String
    let seats : String
    let meetings : [Meeting]
    let open_seats : String
    let waitlist : String
    let instructors : [String]
}

struct Meeting : Codable, Hashable {
    static func == (lhs: Meeting, rhs: Meeting) -> Bool {
        return lhs.room == rhs.room && lhs.start_time == rhs.start_time
    }
    
    let days : String
    let room : String
    let building : String
    let classtype : String
    let start_time : String
    let end_time : String
}

// Second, planetterp (https://api.planetterp.com/v1) We use this API in two ways -- get prof ratings & get class avg. GPA's

// 1: /professor?name=<prof_name>
// We only really care about average rating here, but we need the rest of the entries to load the response properly
struct ProfResponse : Codable {
    let name : String
    let slug : String
    let type : String
    let courses : [String]
    let average_rating : Float
}

// Getting class average GPA's is a bit more involved. The more direct, generalized, way is to just get the avg. GPA for a given course_id, like so:

// 2.1: /course?name=<course_id>
// * NOTE: <course_id> here is the same format is it was for the umd.io api (e.g. "cmsc131")
// Again, like above, we only really care about average gpa here, but we need the rest of the entries to load the response properly

struct CourseGPAResponse : Codable {
    let department : String
    let course_number : String
    let title : String
    let description : String
    let credits : Int
    let professors : [String]
    let average_gpa : Float
}

// Ideally, we'd like to get avg. GPA's for the class when the prof in question was teaching it (so it's most accurate -- for example, if Class A has two profs, Bob and Alice, and only Bob is teaching this sem, we only want the avg. GPA for when Bob has taught Class A).

// 2.2: /grades?course=<course_id>&professor=<prof_name>
// * NOTE: for now, we won't implement this because the response is a massive array of every single recorded section <prof_name> has taught of <course_id>, and we doubt that we'll get a significant difference in avg. gpa (not worth the computational load)
// Each entry lists how many individiduals got an A+, A, A-, ... , D-, F. Computing gpa for this & then averaging it is just overkill (at least as of 11/26/21)

//struct ProfGPAResponse : Codable {
//    let course : String
//    let professor : String
//    let semester : String
//    let section : String
//    let A+ : Int
//    let A : Int
//    let A- : Int
//    let B+ : Int
//    let B : Int
//    let B- : Int
//    let C+ : Int
//    let C : Int
//    let C- : Int
//    let D+ : Int
//    let D : Int
//    let D- : Int
//    let F : Int
//    let W : Int
//    let Other : Int
//}

// ************************************************************************************************* //

// Now that we've set the required structs to hold the JSON responses, we can proceed to working on our own design
// We don't need most of the associated info that either API gives us, so let's make a condensed version in our own definition of a section & a course:

struct Times : Hashable {
    static func == (lhs: Times, rhs: Times) -> Bool {
        return lhs.room == rhs.room && lhs.start_time == rhs.start_time
    }
    
    let days : String
    let room : String
    let building : String
    let classtype : String
    let start_time : String
    let end_time : String
    
    // members for time conflicts
    let start_time_float : Float
    let end_time_float : Float
}

struct Section : Hashable {
    static func == (lhs: Section, rhs: Section) -> Bool {
        return lhs.section_id == rhs.section_id
    }
    
    var course_id : String
    var course_name : String
    var section_id : String
    var number : String
    var prof : [String]
    var prof_rating : Float
    var avg_gpa : Float
    var open_seats : String
    var waitlist : String
    var credits : Int
    var times : [Times]
}

struct Course : Hashable {
    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.course_id == rhs.course_id
    }
    var course_id : String
    var course_name : String
    var sections : [Section]
}


struct Saved : Hashable {
    static func == (lhs: Saved, rhs: Saved) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id: UUID = UUID()
    var save_img : String = "bookmark"
    var save_text : String = "Save"
    var save_padding : CGFloat? = 50
    var calendar_img : String = "calendar.badge.plus"
    var calendar_text : String = "Add to Calendar"
    var calendar_saved: Bool = false //Keeps track of the state of the calendar toggle. False -> no events on calendar so add them. True-> events are on calendar so remove them
    
    mutating func toggle_save(){
        if save_img == "bookmark" {
            save_img = "bookmark.fill"
            save_text = "Unsave"
            save_padding = (calendar_text == "Remove from Calendar") ? 10 : 40
        } else {
            save_img = "bookmark"
            save_text = "Save"
            save_padding = (calendar_text == "Remove from Calendar") ? 30 : 50
        }
    }
    
    mutating func toggle_calendar(){
        if calendar_img == "calendar.badge.plus" {
            calendar_img = "calendar.badge.minus"
            calendar_text = "Remove from Calendar"
            save_padding = (save_text == "Unsave") ? 10 : 30
            calendar_saved = true
        } else {
            calendar_img = "calendar.badge.plus"
            calendar_text = "Add to Calendar"
            save_padding = 50
            calendar_saved = false
        }

    }
}


struct Schedule : Hashable {
    static func == (lhs: Schedule, rhs: Schedule) -> Bool {
        return lhs.id == rhs.id
    }
    
    let id : UUID = UUID()
    var saved : Saved = Saved()
    var rank : Int
    var score : Float
    var sections : [Section]
}

// Our class holds only two instance variables: courses (the course list that a student is adding/removing to in the UI) and schedules (the result of hitting the "GO" button -- all the possible schedules)

// Note that schedules are not collections of courses, rather they are collections of specific sections.
// This is an important distinction moving forward

class ScheduleBuilder : ObservableObject {
    let tstdo_url = "https://api.umd.io/v1/"
    let pt_url = "https://api.planetterp.com/v1/"
    
    let store = EKEventStore() //store is the user calendar
    var calendar_events:[EKEvent] // A list of events in the user's calendar
    

    @Published var courses : [Course]
    @Published var schedules : [Schedule]
    @Published var bookmarks : [Schedule]
    
    init() {
        courses = []
        schedules = []
        bookmarks = []
        calendar_events = []
        
        //Request access from the user to edit their calendar in the schedule builder
        store.requestAccess(to: .event) { granted, error in
            // Handle the response to the request.
        }
    }
    
    // provides functionality for the "RESET" button in our UI
    func reset_courses() {
        courses = []
    }
    
    // provides functionality for the "BUILD" button in our UI
    func reset_schedules() {
        schedules = []
    }
    
    // GET course, returns the full JSON representation of a course outlined on lines 17-41
    // TO-DO: set a diff return type for failure cases
    func get_course(_ course_id : String) -> [CourseResponse]? {
        let sanitized_id = course_id.replacingOccurrences(of: " ", with: "")
        let url = "\(tstdo_url)courses/\(sanitized_id)"
        let semaphore = DispatchSemaphore(value: 0)
        var course_res : [CourseResponse]? = nil

        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : [CourseResponse]?
            do {
                res = try JSONDecoder().decode([CourseResponse].self, from: data)
            } catch {
                print("Get_Course Error: \(error)")
                course_res = nil
            }
            
            // print(json)
            course_res = res
            semaphore.signal()
            
        })
        
        task.resume()
        semaphore.wait()
        return course_res
    }
    
    // GET section, returns the full JSON representation of a section outlined on lines 46-69
    // TO-DO: set a diff return type for failure cases
    func get_section(_ section_id : String) -> SectionResponse  {
        let url = "\(tstdo_url)courses/sections/\(section_id)"
        let semaphore = DispatchSemaphore(value: 0)
        var section_res : [SectionResponse]? = nil

        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No section found!")
                return
            }
            var res : [SectionResponse]?
            do {
                res = try JSONDecoder().decode([SectionResponse].self, from: data)
            } catch {
                print("Get_Section Error: \(error)")
            }
            
            guard let json = res else {
                return
            }
            
            // print(json)
            section_res = json
            semaphore.signal()
            
        })
        
        task.resume()
        semaphore.wait()
        return section_res![0]
    }
    
    // GET gpa, returns Float representation of course_id's GPA if found
    // TO-DO: set a diff return type for failure cases
    func get_gpa(_ course_id : String) -> Float {
        let url = "\(pt_url)course?name=\(course_id)"
        
        let semaphore = DispatchSemaphore(value: 0)
        // defaults to 3.0 if we dont have course data
        var avg_gpa : Float = 3.0

        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : CourseGPAResponse?
            do {
                res = try JSONDecoder().decode(CourseGPAResponse.self, from: data)
                avg_gpa = res!.average_gpa
            } catch {
                print("Get_GPA Error: \(error)")
            }
            
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        return avg_gpa

    }
    
    // GET prof rating, returns Float representation of prof_name's rating if found
    // TO-DO: set a diff return type for failure cases
    func get_prof(_ prof_name : String) -> Float {
        // we need to replace space with %20 for URL to work
        let sanitized_name = prof_name.replacingOccurrences(of: " ", with: "%20")
        let url = "\(pt_url)professor?name=\(sanitized_name)"
        
        let semaphore = DispatchSemaphore(value: 0)
        // default rating in case we cant find the prof is median of 3.0
        var prof_rating : Float = 3.0

        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : ProfResponse?
            do {
                res = try JSONDecoder().decode(ProfResponse.self, from: data)
                prof_rating = res!.average_rating
            } catch {
                print("Get_Prof Error: \(error)")
            }
            
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        return prof_rating
    }
    
//    func get_prof_gpa(_ course_id : String, _ prof_name : String) -> Float {
//        // /grades?course=<course_id>&professor=<prof_name>
//        let sanitized_name = prof_name.replacingOccurrences(of: " ", with: "%20")
//        let url = "\(pt_url)grades?course=\(course_id)&professor=\(sanitized_name)"
//
//        let semaphore = DispatchSemaphore(value: 0)
//        var prof_gpa_res : [ProfGPAResponse]? = nil
//        // set default gpa to course gpa
//        var avg_gpa : Float = get_gpa(course_id)
//
//        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
//            guard let data = data, error == nil else {
//                print("No course found!")
//                return
//            }
//            var res : [ProfGPAResponse]?
//            do {
//                res = try JSONDecoder().decode([ProfGPAResponse].self, from: data)
//                prof_gpa_res = res
//            } catch {
//                print("Error: Failed to convert \(error)")
//            }
//
//            semaphore.signal()
//        })
//
//        task.resume()
//        semaphore.wait()
//
//        // if we dont have data we're just gonna use the get_gpa function
//        if prof_gpa_res == nil {
//            return avg_gpa
//        }
//
//        let prof_gpa_arr : [ProfGPAResponse] = prof_gpa_res!
//
//        var total_students = 0
//        var total_gpa : Float = 0
//
//        for section in prof_gpa_arr {
//            // section.grade gives the number of students with that grade
//            total_gpa += Float(section.a_plus) * 4.0 + Float(section.a) * 4.0 + Float(section.a_minus) * 3.7 +
//                         Float(section.b_plus) * 3.3 + Float(section.b) * 3.0 + Float(section.b_minus) * 2.7 +
//                         Float(section.c_plus) * 2.3 + Float(section.c) * 2.0 + Float(section.c_minus) * 1.7 +
//                         Float(section.d_plus) * 1.3 + Float(section.d) * 1.0 + Float(section.d_minus) * 0.7
//            total_students += section.a_plus + section.a + section.a_minus +
//                              section.b_plus + section.b + section.b_minus +
//                              section.c_plus + section.c + section.c_minus +
//                              section.d_plus + section.d + section.d_minus + section.f
//        }
//
//        avg_gpa = total_gpa / Float(total_students)
//        return avg_gpa
//    }
//
   
    func parse_time(_ time : String) -> Float {
        // time format "8:50am"
        if time.count == 0 {
            return MAXFLOAT
        }
        let time_split = time.split(separator: ":")
        var hours : Float = Float(time_split[0])!
        let mins : Float = Float(time_split[1].prefix(2))! / 60.0
        let am_pm = time_split[1].suffix(2)
        
        if am_pm == "pm" && hours < 12 { hours += 12.0}
        
        return hours + mins
    }
    
    // use the 4 methods above to build the Section and Course structs
    // Returns the course, TO-DO: set a diff return type for failure cases
    func build_course(_ course_id : String) -> Course? {
        let course_arr = get_course(course_id)
        var sections : [Section] = []
        
        if course_arr == nil {
            return nil
        }
        
        let course : CourseResponse = course_arr![0]
        
        for section_id in course.sections {
            let section = get_section(section_id)
            
            // we need to compute avg rating of profs
            var prof_ratings : Float = 0
            // var prof_gpas : Float = 0
            for prof in section.instructors {
                prof_ratings += get_prof(prof)
                // prof_gpas += get_prof_gpa(course.course_id, prof)
            }
            
            let avg_rating = prof_ratings/Float(section.instructors.count)
            let avg_gpa = get_gpa(course.course_id)
            // let avg_gpa = prof_gpas/Float(section.instructors.count)
            
            var times_arr : [Times] = []
            // we need to build the times object
            for meeting in section.meetings {
                // each one of these is a Meeting object
                times_arr.append(Times(days: meeting.days, room: meeting.room, building: meeting.building, classtype: meeting.classtype, start_time: meeting.start_time, end_time: meeting.end_time, start_time_float: parse_time(meeting.start_time), end_time_float: parse_time(meeting.end_time)))
            }
            
            sections.append(Section(course_id: course.course_id, course_name: course.name, section_id: section_id, number: section.number, prof: section.instructors, prof_rating: avg_rating, avg_gpa: avg_gpa, open_seats: section.open_seats, waitlist: section.waitlist, credits: Int(course.credits)!, times: times_arr))
        }
        
        return Course(course_id: course.course_id, course_name: course.name, sections: sections)
    }
    
    // This is triggered every time a student picks a new course to add
    // Returns 0 (true) on success, else returns one of three error codes:
    // 1: course
    func add_course(_ course_id : String) -> Int {
        if courses.count == 5 {
            return 3
        }
        
        // first make sure that the course isn't already in the course list
        
        for c in courses {
            if c.course_id == course_id.uppercased() {
                return 2
            }
        }
        
        // build course before you add it
        let new_course = build_course(course_id)
        
        if new_course == nil {
            return 1
        }
        
        courses.append(new_course!)
        
        print(new_course!.sections[0].prof_rating)
        
        return 0
    }
    
    // This is triggered every time a student removes a course from their course-list
    func remove_course(_ course_id : String) {
        courses = courses.filter {$0.course_id != course_id}
    }
    
    // Prints out the course-list -- for testing purposes
    func print_courses() {
        for course in self.courses {
            print(course)
        }
        print("")
    }
    
    func overlap(a : [Float], b : [Float]) -> Bool {
        // we effectively need to check if two ranges overlap, quickly
        // we have a = [a.start,a.end] and b = [b.start,b.end]
        
        // if either time is online/undefined
        if a[0] == MAXFLOAT || a[1] == MAXFLOAT || b[0] == MAXFLOAT || b[1] == MAXFLOAT {
            return false
        }
        
        // case 1, a starts before (or at the same time as) b and ends after (or at the same time as) b
        if a[0] <= b[0] && a[1] >= b[1] {
            return true
        
        // case 2, a starts after b and ends before b
        } else if a[0] > b[0] && a[1] < b[1] {
            return true
        
        // case 3 a starts after b but before the end of b
        } else if a[0] > b[0] && a[0] < b[1] {
            return true
        
        // case 4, a starts before b but ends during b
        } else if a[0] < b[0] && a[1] > b[0] && a[1] < b[1] {
            return true
        } else {
            return false
        }
        
    }
    
    // Helper method to make sure any schedule our algo puts together is structurally valid
    // Returns true if there is a time conflict, else false
    func time_conflict(_ schedule : Schedule) -> Bool {
        // iterate through sections in the provided list, if there is a time conflict get rid of it
        // we want to check all pairs of sections in the schedules (O(n^2))
        let num_sections = schedule.sections.count
        let week = ["M","Tu","W","Th","F"]
        for i in 0..<num_sections {
            for j in i+1..<num_sections+1 {
                if j == num_sections { continue }
                let s1 : Section = schedule.sections[i]
                let s2 : Section = schedule.sections[j]
                // now we want to check time conflicts for these schedules
                
                // define a conflict: if a starts while b is going on, or it ends while b is going on, we have a conflict
                //                    if a.start in range(b.start,b.end) || a.end in range(b.start,b.end)
                // only if a and b are on the same day
                for a in s1.times {
                    // add the times to our array
                    for b in s2.times {
                        // check conflict for any combo of times
                        for day in week {
                            // if they both occur on the same day
                            if a.days.contains(day) && b.days.contains(day){
                                let overlap = overlap(a: [a.start_time_float, a.end_time_float], b: [b.start_time_float,b.end_time_float])
                                if overlap { return true }
                            }
                        }
                    }
                }
                
                
            }
        }
        
        return false
    }
    
    // ******* TO-DO: IMPLEMENT ********* //
    // For any given schedule, use prof ratings + avg gpa of each section to score
    // Weigh scores by credits (i.e. if a 1 credit class has a bad prof, it matters less than if a 4 credit class has a bad prof)
    func get_score(_ sections : [Section]) -> Float {
        
        // let n = number of sections
        // FORMULA: score = sum_i_1_to_n(section[i].avg_gpa * section[i].prof_rating * section[i].credits) / credits
        var total_credits = 0
        var score : Float = 0
        // ok so a schedule has sections.
        for section in sections {
            // do the checks
            total_credits += section.credits
            score += section.avg_gpa * section.prof_rating * Float(section.credits)
        }
        
        // catch div_by_zero error -- this means that planet terp didn't have data for any courses
        if total_credits == 0 {
            score = MAXFLOAT
        }
        
        score /= Float(total_credits)

        return score
    }
    
    // Generate all combos of schedules for the courselist (self.courses)
    func build_schedules() {
        // combine all combos of sections of the classes in the <courses> instance variable
        
        // first we need to reset schedules in case it was called earlier
        reset_schedules()
        
        
        let default_rank : Int = -1
        let num_courses = courses.count
        
        switch num_courses {
        case 1:
            for s in courses[0].sections {
                let sections : [Section] = [s]
                let schedule : Schedule = Schedule(rank: default_rank, score: get_score(sections), sections: sections)
                schedules.append(schedule)
            }
            
        case 2:
            for s_0 in courses[0].sections {
                for s_1 in courses[1].sections {
                    let sections : [Section] = [s_0, s_1]
                    let schedule : Schedule = Schedule(rank: default_rank, score: get_score(sections), sections: sections)
                    if !time_conflict(schedule) {
                        schedules.append(schedule)
                    }
                }
            }
        case 3:
            for s_0 in courses[0].sections {
                for s_1 in courses[1].sections {
                    for s_2 in courses[2].sections {
                        let sections : [Section] = [s_0, s_1, s_2]
                        let schedule : Schedule = Schedule(rank: default_rank, score: get_score(sections), sections: sections)
                        if !time_conflict(schedule) {
                            schedules.append(schedule)
                        }                    }
                }
            }
        case 4:
            for s_0 in courses[0].sections {
                for s_1 in courses[1].sections {
                    for s_2 in courses[2].sections {
                        for s_3 in courses[3].sections {
                            let sections : [Section] = [s_0, s_1, s_2, s_3]
                            let schedule : Schedule = Schedule(rank: default_rank, score: get_score(sections), sections: sections)
                            if !time_conflict(schedule) {
                                schedules.append(schedule)
                            }                        }
                    }
                }
            }
        case 5:
            for s_0 in courses[0].sections {
                for s_1 in courses[1].sections {
                    for s_2 in courses[2].sections {
                        for s_3 in courses[3].sections {
                            for s_4 in courses[4].sections {
                                let sections : [Section] = [s_0, s_1, s_2, s_3, s_4]
                                let schedule : Schedule = Schedule(rank: default_rank, score: get_score(sections), sections: sections)
                                if !time_conflict(schedule) {
                                    schedules.append(schedule)
                                }                            }
                        }
                    }
                }
            }
            
        default:
            // if they choose more than 5 classes, it becomes O(n^6), where n is the avg number of sections per course
            // print("That's too many classes! Ease up!")
            schedules = []
        }
        
        // ******* TO-DO: IMPLEMENT ********* //
        // make sure to sort schedules by score (ML)
        schedules.sort(by: {$0.score > $1.score})
        
        // rank after sorting
        let num_schedules = schedules.count
        for i in 0..<num_schedules {
            schedules[i].rank = i+1
            // print(schedules[i].score)
        }
    }
    
    // Print all the schedules we generated (for testing)
    func print_schedules() {
        print("You selected the following courses:")
        for course in courses {
            print(course.course_id)
        }
        print("")
        
        print("\(schedules.count) Schedules Generated")
        for schedule in schedules {
            for section in schedule.sections {
                print(section.section_id, section.times[0].days, section.times[0].start_time, section.times[0].end_time)
            }
            print("")
        }
    }
    
    
    func toggle_save(_ s_id : UUID) {
        var needsToBeBookmarked = true
        // if its in bookmarks, remove it. otherwise add it
        for i in 0..<bookmarks.count {
            if bookmarks[i].id == s_id {
                needsToBeBookmarked = false
                bookmarks.remove(at: i)
                break
            }
        }
        
        for i in 0..<schedules.count {
            // print(schedules[i].id)
            if schedules[i].id == s_id {
                schedules[i].saved.toggle_save()
                if needsToBeBookmarked { bookmarks.append(schedules[i]) }
                break
            }
        }
    }
    
    // ******* TO-DO: IMPLEMENT ACTUAL CALENDAR FUNCTIONS ********* //
    func toggle_calendar(_ s_id : UUID) {
        for i in 0..<schedules.count {
            if schedules[i].id == s_id {
                
                //if the calendar is toggled to true, delete the events from the calendar and toggle it
                if schedules[i].saved.calendar_saved == true{
                    remove_all() //removes all of the calendar events
                    schedules[i].saved.toggle_calendar()
                    break
                }
                
                //otherwise if the calendar is toggled to false, add the specified courses to the calendar
                let sections_to_save = schedules[i].sections
                
                //for each section, get the title of the course
                for j in 0..<sections_to_save.count {
                    let curr_section = sections_to_save[j]
                    let class_name = curr_section.course_name
                    let class_id = curr_section.course_id
                    
                    //for each time struct in the section, create an event with the course name and the times specified within the struct
                    for k in 0..<curr_section.times.count {
                        let curr_time = curr_section.times[k]
                        
                        let days_string = curr_time.days //days that the class meets
                        let start_time_string = curr_time.start_time
                        let end_time_string = curr_time.end_time
                        
                        //parse the start time into the proper format. Needs to be in hours (0-23), and minutes (0-60)
                        let start_time_split = start_time_string.split(separator: ":")
                        var start_hours : Int = Int(start_time_split[0])!
                        let start_mins : Int = Int(start_time_split[1].prefix(2))!
                        let start_am_pm = start_time_split[1].suffix(2)
                        if start_am_pm == "pm" && start_hours < 12 { start_hours += 12}
                        
                        //parse end time manually. Our helper function can't do this since we need minutes as 0-60
                        let end_time_split = end_time_string.split(separator: ":")
                        var end_hours : Int = Int(end_time_split[0])!
                        let end_mins : Int = Int(end_time_split[1].prefix(2))!
                        let end_am_pm = end_time_split[1].suffix(2)
                        if end_am_pm == "pm" && end_hours < 12 { end_hours += 12}
                        
                        //create the recurrence rule for the event
                        //The spring semester starts on January 24th, 2022
                        //The spring semester ends on May 10th, 2022
                        let semester_end_date = create_date(year: 2022, month: 5, day: 11, hour: 0, minute: 0)
                        
                        //find out the days of the week the event will recur
                        var recurring_days: [EKRecurrenceDayOfWeek] = []
                        
                        //build the list containing the days of the week for the reccurence
                        if days_string.contains("M"){
                            recurring_days.append(EKRecurrenceDayOfWeek(.monday))
                        }
                        if days_string.contains("Tu"){
                            recurring_days.append(EKRecurrenceDayOfWeek(.tuesday))
                        }
                        if days_string.contains("W"){
                            recurring_days.append(EKRecurrenceDayOfWeek(.wednesday))
                        }
                        if days_string.contains("Th"){
                            recurring_days.append(EKRecurrenceDayOfWeek(.thursday))
                        }
                        if days_string.contains("F"){
                            recurring_days.append(EKRecurrenceDayOfWeek(.friday))
                        }
                        if days_string.contains("Sa"){
                            recurring_days.append(EKRecurrenceDayOfWeek(.saturday))
                        }
                        if days_string.contains("Su"){
                            recurring_days.append(EKRecurrenceDayOfWeek(.sunday))
                        }
                       
                        //set up the recurrence rule
                        let rule = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.weekly, interval: 1, daysOfTheWeek: recurring_days, daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil, daysOfTheYear: nil, setPositions: nil, end: EKRecurrenceEnd(end: semester_end_date))
                        
                        var class_start:Date
                        var class_end:Date
                        
                        //create the event depending on which day of the week it first starts on
                        //first monday of spring semester is 1/24/2022
                        if days_string.contains("M"){
                            class_start = create_date(year: 2022, month: 1, day: 24, hour: start_hours, minute: start_mins)
                            class_end = create_date(year: 2022, month: 1, day: 24, hour: end_hours, minute: end_mins)
                        }
                        
                        //first tuesday of spring semester is 1/25/2022
                        else if days_string.contains("Tu"){
                            class_start = create_date(year: 2022, month: 1, day: 25, hour: start_hours, minute: start_mins)
                            class_end = create_date(year: 2022, month: 1, day: 25, hour: end_hours, minute: end_mins)
                        }
                        //first wednesday of spring semester is 1/26/2022
                        else if days_string.contains("W"){
                            class_start = create_date(year: 2022, month: 1, day: 26, hour: start_hours, minute: start_mins)
                            class_end = create_date(year: 2022, month: 1, day: 26, hour: end_hours, minute: end_mins)
                        }
                        //first thursday of spring semester is 1/27/2022
                        else if days_string.contains("Th"){
                            class_start = create_date(year: 2022, month: 1, day: 27, hour: start_hours, minute: start_mins)
                            class_end = create_date(year: 2022, month: 1, day: 27, hour: end_hours, minute: end_mins)
                        }
                        //first friday of spring semester is 1/28/2022
                        else if days_string.contains("F"){
                            class_start = create_date(year: 2022, month: 1, day: 28, hour: start_hours, minute: start_mins)
                            class_end = create_date(year: 2022, month: 1, day: 28, hour: end_hours, minute: end_mins)
                        }
                        //first saturday of spring semester is 1/29/2022
                        else if days_string.contains("Sa"){
                            class_start = create_date(year: 2022, month: 1, day: 29, hour: start_hours, minute: start_mins)
                            class_end = create_date(year: 2022, month: 1, day: 29, hour: end_hours, minute: end_mins)
                        }
                        //first sunday of spring semester is 1/30/2022
                        else {
                            class_start = create_date(year: 2022, month: 1, day: 30, hour: start_hours, minute: start_mins)
                            class_end = create_date(year: 2022, month: 1, day: 30, hour: end_hours, minute: end_mins)
                        }
                        
                        //in the notes of the event, include the other information like instructor, room number, etc.
                        let event_notes = "Professor: \(curr_section.prof) Room: \(curr_time.room) Building: \(curr_time.building)"
                        
                        //now that we have the class start and class end, we can create the event and add it to the calendar
                        let event_name = "\(class_id): \(class_name)"
                        let event_added = add_to_calandar(title: event_name, start_date: class_start, end_date: class_end, notes: event_notes, rule: rule)
                        
                        //add the new event to our event list instance member
                        calendar_events.append(event_added)
                    }
                }
                schedules[i].saved.toggle_calendar()
            }
        }
        
    }
    
    //Removes all added events from the apple calendar
    func remove_all() {
        //for each event in the calendar events list, delete all occurences of it it from the calendar
        for i in 0..<calendar_events.count {
            delete(event_to_delete: calendar_events[i])
        }
        //reset the calendar events list to an empty list
        calendar_events = []
    }
    
    //Removes a specified event from the user's apple calendar
    func delete(event_to_delete:EKEvent) {
        do {
            try store.remove(event_to_delete, span: EKSpan.futureEvents, commit: true)

        } catch {
            print("error in removing the event from the calandar")
        }
    }
    
    //Adds an event with the specified information to the user's calendar
    func add_to_calandar(title:String, start_date:Date, end_date:Date, notes:String, rule:EKRecurrenceRule) -> EKEvent{
        let newEvent:EKEvent = EKEvent(eventStore: store)
        newEvent.title = title
        newEvent.startDate = start_date
        newEvent.endDate = end_date
        newEvent.notes = notes
        newEvent.calendar = store.defaultCalendarForNewEvents
        newEvent.recurrenceRules = [rule]
        do {
            try store.save(newEvent, span: EKSpan.futureEvents, commit: true)

        } catch {
            print("Error in adding the event to the calandar")
        }
        return newEvent
    }
    
    //Creates a date object with the specified inputs
    func create_date(year:Int, month:Int, day:Int, hour:Int, minute:Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Create date from components
        let userCalendar = Calendar(identifier: .gregorian) // since the components above are for Gregorian
        let output_date = userCalendar.date(from: dateComponents)
        return output_date!
    }
}

