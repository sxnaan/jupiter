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
// This gives us a host of data points on <course_id>, but it's most important functions are 1) letting us
// know if it's actually a real class (no 404 response) and 2) showing us what sections are being offered for the class

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
// The first API call (/courses/<course_id>) gives us access to an array called "sections". Each entry of this array is a diff section_id
// that we can pass into this API call, which gives us times, profs, etc -- all material we need to build the schedule

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

struct Meeting : Codable {
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

// Getting class average GPA's is a bit more involved. The more direct, generalized, way is to just get the avg. GPA
// for a given course_id, like so:

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

// Ideally, we'd like to get avg. GPA's for the class when the prof in question was teaching it (so it's most accurate -- for example,
// if Class A has two profs, Bob and Alice, and only Bob is teaching this sem, we only want the avg. GPA for when Bob has taught Class A).

// 2.2: /grades?course=<course_id>&professor=<prof_name>
// * NOTE: for now, we won't implement this because the response is a massive array of every single recorded section <prof_name> has taught
// of <course_id>, and we doubt that we'll get a significant difference in avg. gpa (not worth the computational load)
// Each entry lists how many individiduals got an A+, A, A-, ... , D-, F. Computing gpa for this & then averaging it is just overkill
// (at least as of 11/26/21)

// ************************************************************************************************* //

// Now that we've set the required structs to hold the JSON responses, we can proceed to working on our own design
// We don't need most of the associated info that either API gives us, so let's make a condensed version in our own definition of a section & a course:

struct Section {
    var course_name : String
    var course_id : String
    var section_id : String
    var prof : [String]
    var prof_rating : Float
    var avg_gpa : Float
    var open_seats : Int
    var waitlist : Int
    var times : [Meeting]
}

struct Course {
    var course_id : String
    var sections : [Section]
}

// Our class holds only two instance variables: courses (the course list that a student is adding/removing to in the UI)
// and schedules (the result of hitting the "GO" button -- all the possible schedules)

// Note that schedules are not collections of courses, rather they are collections of specific sections.
// This is an important distinction moving forward

class ScheduleBuilder : ObservableObject {
    let tstdo_url = "https://api.umd.io/v1/"
    let pt_url = "https://api.planetterp.com/v1/"
    
    var courses : [Course]
    var schedules : [[Section]]
    
    init() {
        courses = []
        schedules = []
    }
    
    // provides functionality for the "RESET" button in out UI
    func reset_courses() {
        courses = []
    }
    
    // GET course (returns the full json response outlined on lines 18-42)
    func get_course(_ course_id : String) -> CourseResponse {
        let url = "\(tstdo_url)courses/\(course_id)"
        var course_res : [CourseResponse]? = nil
            
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : [CourseResponse]?
            do {
                res = try JSONDecoder().decode([CourseResponse].self, from: data)
            } catch {
                print("Error: Failed to convert \(error)")
            }
            
            guard let json = res else {
                return
            }
            
            // print(json)
            course_res = json
            
        }).resume()
        return course_res![0]
    }
    
    // GET section (returns the full json response outlined on lines 48-67)
    func get_section(_ section_id : String) -> SectionResponse {
        let url = "\(tstdo_url)courses/sections/\(section_id)"
        var sect_res : [SectionResponse]? = nil
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : [SectionResponse]?
            do {
                res = try JSONDecoder().decode([SectionResponse].self, from: data)
            } catch {
                print("Error: Failed to convert \(error)")
            }
            
            guard let json = res else {
                return
            }
            
            // print(json)
            sect_res = json
            
        }).resume()
        return sect_res![0]
    }
    
    // GET prof rating
    func get_prof(_ prof_name : String) -> Float {
        let url = "\(pt_url)/professor?name=\(prof_name)"
        var rating : Float = -1
        
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
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
            rating = json.average_rating
        }).resume()
        return rating
    }
    
    // GET gpa
    func get_gpa(_ course_id : String) -> Float {
        let url = "\(pt_url)/grades?course=\(course_id)"
        var gpa : Float = -1
        
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: {data, response, error in
            guard let data = data, error == nil else {
                print("No course found!")
                return
            }
            var res : CourseGPAResponse?
            do {
                res = try JSONDecoder().decode(CourseGPAResponse.self, from: data)
            } catch {
                print("Error: Failed to convert \(error)")
            }
            
            guard let json = res else {
                return
            }
            
            // print(json)
            gpa = json.average_gpa
        }).resume()
        
        return gpa
    }
    
    // use the 4 methods above to build the Section and Course structs
    func build_course(_ course_id : String) -> Course {
        let course_json = get_course(course_id)
        var sections : [Section] = []
        var section : Section? = nil
        for s_id in course_json.sections {
            let sect_json = get_section(s_id)
            var prof_ratings : Float = 0
            var num_profs = sect_json.instructors.count
            for prof in sect_json.instructors {
                let prof_rating = get_prof(prof)
                if prof_rating == -1 {
                    num_profs -= 1
                    continue
                } else {
                    prof_ratings += prof_rating
                }
            }
            
            // get average
            let avg_prof_rating = prof_ratings / Float(sect_json.instructors.count)
            
            section = Section(course_name: course_json.name, course_id: course_id, section_id: sect_json.section_id, prof: sect_json.instructors, prof_rating: avg_prof_rating, avg_gpa: get_gpa(course_id), open_seats: Int(sect_json.open_seats)!, waitlist: Int(sect_json.waitlist)!, times: sect_json.meetings)
            sections.append(section!)
        }
        
        return Course(course_id: course_json.course_id, sections: sections)
        
    }
    
    // This is triggered every time a student picks a new course to add
    func add_course(course_id : String) -> Bool {
        // first make sure that the course isn't already in the course list
        for c in courses {
            if c.course_id == course_id {
                return false
            }
        }
        
        let course = build_course(course_id)
        courses.append(course)
        
        return true
    }
    
    // This is triggered every time a student removes a course from their course-list
    func remove_course(course_id : String) -> Bool {
        let len = courses.count
        courses = courses.filter {$0.course_id != course_id}
        
        if courses.count == len {
            return false
            // nothing was removed bc course wasn't in courses
        }
        
        return true
    }
    
    // Helper method to make sure any schedule our algo puts together is structurally valid
    func time_conflict() -> Bool {
        // iterate through courses in the provided list, if there is a problem get rid
        
        return false
    }
    
    // from the course list, build all possible schedules
    func get_score(schedule : [Section]) -> Float {
        return 0
    }
    
    func build_schedules() -> [[Section]] {
        var schedules : [[Section]] = []
        // combine all combos of sections of the classes in the <courses> instance variable
        
        
        // make sure to sort schedules by score (ML)
        
        return schedules
    }
    
}

