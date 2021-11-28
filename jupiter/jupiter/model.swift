//
//  model.swift
//  jupiter
//
//  Created by Sinaan Younus on 11/26/21.
//

import Foundation

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

// ************************************************************************************************* //

// Now that we've set the required structs to hold the JSON responses, we can proceed to working on our own design
// We don't need most of the associated info that either API gives us, so let's make a condensed version in our own definition of a section & a course:

struct Section : Hashable {
    static func == (lhs: Section, rhs: Section) -> Bool {
        return lhs.section_id == rhs.section_id
    }
    
    var course_id : String
    var course_name : String
    var section_id : String
    var prof : [String]
    var prof_rating : Float
    var avg_gpa : Float
    var open_seats : Int
    var waitlist : Int
    var credits : Int
    var times : [Meeting]
}

struct Course : Hashable {
    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.course_id == rhs.course_id
    }
    
    var course_id : String
    var sections : [Section]
}

// Our class holds only two instance variables: courses (the course list that a student is adding/removing to in the UI) and schedules (the result of hitting the "GO" button -- all the possible schedules)

// Note that schedules are not collections of courses, rather they are collections of specific sections.
// This is an important distinction moving forward

class ScheduleBuilder : ObservableObject {
    let tstdo_url = "https://api.umd.io/v1/"
    let pt_url = "https://api.planetterp.com/v1/"

    @Published var courses : [Course]
    @Published var schedules : [[Section]]
    
    init() {
        courses = []
        schedules = []
    }
    
    // provides functionality for the "RESET" button in our UI
    func reset_courses() {
        courses = []
    }
    
    // provides functionality for the "BUILD" button in our UI
    func reset_schedules() {
        schedules = []
    }
    
    // GET course
    func get_course(_ course_id : String) -> CourseResponse {
        let url = "\(tstdo_url)courses/\(course_id)"
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
                print("Error: \(error)")
            }
            
            guard let json = res else {
                return
            }
            
            // print(json)
            course_res = json
            semaphore.signal()
            
        })
        
        task.resume()
        semaphore.wait()
        return course_res![0]
    }
    
    // GET section
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
                print("Error: \(error)")
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
    
    // GET prof rating
    func get_prof(_ prof_name : String) -> Float {
        // we need to replace space with %20 for URL to work
        let sanitized_name = prof_name.replacingOccurrences(of: " ", with: "%20")
        let url = "\(pt_url)professor?name=\(sanitized_name)"
        
        let semaphore = DispatchSemaphore(value: 0)
        var prof_rating : Float = -1

        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : ProfResponse?
            do {
                res = try JSONDecoder().decode(ProfResponse.self, from: data)
            } catch {
                print("Error: Failed to convert \(error)")
            }
            
            guard let json = res else {
                return
            }
            
            // print(json)
            prof_rating = json.average_rating
            semaphore.signal()
            
        })
        
        task.resume()
        semaphore.wait()
        return prof_rating
    }
    
    // GET gpa
    func get_gpa(_ course_id : String) -> Float {
        let url = "\(pt_url)course?name=\(course_id)"
        
        let semaphore = DispatchSemaphore(value: 0)
        var avg_gpa : Float = -1

        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : CourseGPAResponse?
            do {
                res = try JSONDecoder().decode(CourseGPAResponse.self, from: data)
            } catch {
                print("Error: Failed to joe \(error)")
            }
            
            guard let json = res else {
                return
            }
            
            // print(json)
            avg_gpa = json.average_gpa
            semaphore.signal()
            
        })
        
        task.resume()
        semaphore.wait()
        return avg_gpa

    }
    
    // use the 4 methods above to build the Section and Course structs
    func build_course(_ course_id : String) -> Course {
        let course = get_course(course_id)
        var sections : [Section] = []
        
        for section_id in course.sections {
            let section = get_section(section_id)
            
            // we need to compute avg rating of profs
            var prof_ratings : Float = 0
            for prof in section.instructors {
                let rating = get_prof(prof)
                prof_ratings += rating
            }
            let avg_rating = prof_ratings/Float(section.instructors.count)
            
            sections.append(Section(course_id: course.course_id, course_name: course.name, section_id: section_id, prof: section.instructors, prof_rating: avg_rating, avg_gpa: get_gpa(course_id), open_seats: Int(section.open_seats)!, waitlist: Int(section.waitlist)!, credits: Int(course.credits)!, times: section.meetings))
        }
        
        return Course(course_id: course.course_id, sections: sections)
    }
    
    // This is triggered every time a student picks a new course to add
    func add_course(_ course_id : String) -> Bool {
        // first make sure that the course isn't already in the course list
        for c in courses {
            if c.course_id == course_id {
                return false
            }
        }
        
        // build course before you add it
        let new_course = build_course(course_id)
        courses.append(new_course)
        
        return true
    }
    
    // This is triggered every time a student removes a course from their course-list
    func remove_course(_ course_id : String) -> Bool {
        let len = courses.count
        courses = courses.filter {$0.course_id != course_id}
        
        if courses.count == len {
            return false
            // nothing was removed bc course wasn't in courses
        }
        
        return true
    }
    
    // Prints out the course-list
    func print_courses() {
        for course in self.courses {
            print(course)
        }
        print("")
    }
    
    // Helper method to make sure any schedule our algo puts together is structurally valid
    func time_conflict(_ schedule : [Section]) -> Bool {
        // iterate through sections in the provided list, if there is a time conflict get rid of it
        // we want to check all pairs of sections in the schedules (O(n^2))
        return false
    }
    
    // For any given schedule, use prof ratings + avg gpa of each section to score
    // Weigh scores by credits (i.e. if a 1 credit class has a bad prof, it matters less than if a 4 credit class has a bad prof)
    func get_score(schedule : [Section]) -> Float {
        return 0
    }
    
    // Generate all combos of schedules for the courselist (self.courses)
    func build_schedules() -> [[Section]] {
        // combine all combos of sections of the classes in the <courses> instance variable
        
        // first we need to reset schedules in case it was called earlier
        reset_schedules()
        
        let num_courses = courses.count
        
        switch num_courses {
        case 1:
            schedules.append(courses[0].sections)
        case 2:
            for s_0 in courses[0].sections {
                for s_1 in courses[1].sections {
                    let schedule : [Section] = [s_0, s_1]
                    if !time_conflict(schedule) {
                        schedules.append(schedule)
                    }
                }
            }
        case 3:
            for s_0 in courses[0].sections {
                for s_1 in courses[1].sections {
                    for s_2 in courses[2].sections {
                        let schedule : [Section] = [s_0, s_1, s_2]
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
                            let schedule : [Section] = [s_0, s_1, s_2, s_3]
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
                                let schedule : [Section] = [s_0, s_1, s_2, s_3, s_4]
                                if !time_conflict(schedule) {
                                    schedules.append(schedule)
                                }                            }
                        }
                    }
                }
            }
            
        case 6:
            for s_0 in courses[0].sections {
                for s_1 in courses[1].sections {
                    for s_2 in courses[2].sections {
                        for s_3 in courses[3].sections {
                            for s_4 in courses[4].sections {
                                for s_5 in courses[5].sections {
                                    let schedule : [Section] = [s_0, s_1, s_2, s_3, s_4, s_5]
                                    if !time_conflict(schedule) {
                                        schedules.append(schedule)
                                    }                                }
                            }
                        }
                    }
                }
            }
        default:
            schedules = []
        }
        
        // make sure to sort schedules by score (ML)
        // for each
        
        return schedules
    }
    
    // Print all the schedules we generated
    func print_schedules() {
        print("You selected the following courses:")
        for course in courses {
            print(course.course_id)
        }
        print("")
        
        print("\(schedules.count) Schedules Generated")
        for schedule in schedules {
            for section in schedule {
                print(section.section_id, section.times[0].days, section.times[0].start_time, section.times[0].end_time)
            }
            print("")
        }
    }
    
}

