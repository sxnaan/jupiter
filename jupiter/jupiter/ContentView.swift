//
//  ContentView.swift
//  jupiter
//
//  Created by Sinaan Younus on 11/24/21.
//

import SwiftUI
import CoreData

struct AddCourseErrorView : View {
    @Binding var course_id : String
    @Binding var add_course_error : Int
    var body: some View {
        VStack {
            VStack(alignment:.center){
                Text("ERROR").font(.title).fontWeight(.heavy).foregroundColor(.white)
                switch add_course_error {
                case 1:
                    Text("COURSE \"\(course_id.uppercased())\" NOT FOUND\nPLEASE TRY AGAIN").font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                case 2:
                    Text("COURSE \"\(course_id.uppercased())\" ALREADY ADDED\nPLEASE TRY AGAIN").font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                case 3:
                    Text("COURSE LIMIT REACHED\nTIME TO BUILD!").font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                default:
                    Text("PLEASE TRY AGAIN")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    add_course_error = 0
                } label : {
                    Text("CLOSE")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 20.0)
                                .frame(width: 100, height: 30, alignment: .center)
                                .foregroundColor(.red)
                        )
                }.padding(.top, 50.0)
            }.padding(.bottom, 5.0)
        }.background(
            Rectangle()
                .frame(width: 850, height: 1400, alignment: .center)
                .foregroundColor(Color(red: 0, green: 0, blue: 0, opacity:0.8))
        )
    }
}

struct SchedulesView : View {
    @EnvironmentObject var sb : ScheduleBuilder
    @Binding var schedules : [Schedule]
    @Binding var selected_schedule : Schedule?
    @Binding var selection : Int
    
    func toggle_save(_ schedule_id : UUID) {
        // get schedule
        sb.toggle_save(schedule_id)
    }
    
    func toggle_calendar(_ schedule_id : UUID) {
        sb.toggle_calendar(schedule_id)
    }
    
    var body : some View {
        VStack(alignment: .center) {
            ForEach(schedules, id: \.self) { schedule in
                // this is one schedule
                VStack(alignment: .leading) {
                    HStack{
                        Text("\(schedule.rank).")
                            .font(.title)
                            .frame(width:50)
                            .offset(x: -10, y: 0)
                        Spacer()
                        Button {
                            // action is to change the selected schedule to this one, and then pass it into details view
                            selected_schedule = schedule
                            selection = 2
                        } label : {
                            Text("VIEW DETAILS")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .background(
                                    RoundedRectangle(cornerRadius: 5.0)
                                        .frame(width: 100, height: 20, alignment: .center)
                                        .foregroundColor(.yellow)
                                )
                        }
                    
                    }.frame(width: 300)
                    
                    VStack(alignment: .leading) {
                        ForEach(schedule.sections, id: \.self) { section in
                            HStack(alignment: .top){
                                Text("\(section.section_id)").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                VStack(alignment: .leading){
                                    ForEach(section.times, id: \.self) { meeting in
                                        if meeting.room != "ONLINE" {
                                            Text("\(meeting.days) \(meeting.start_time) - \(meeting.end_time)").fontWeight(.light)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                    HStack {
                        Button {
                            toggle_save(schedule.id)
                        } label : {
                            HStack {
                                Image(systemName: schedule.saved.save_img).foregroundColor(.red)
                                Text(schedule.saved.save_text).foregroundColor(.black)
                            }
                        }.padding(.trailing, schedule.saved.save_padding)
                        Button {
                            toggle_calendar(schedule.id)
                        } label : {
                            HStack {
                                Image(systemName: schedule.saved.calendar_img).foregroundColor(.red)
                                Text(schedule.saved.calendar_text).foregroundColor(.black)
                            }
                        }
                    }
                }.padding()
                 .background(RoundedRectangle(cornerRadius: 20.0)
                                .foregroundColor(Color(red: 0.93, green: 0.93, blue: 0.93))
                                .frame(width: 350)
                                
                                
                                
                 )
                Spacer(minLength: 20)
            }
        }

    }
}

struct BuildView : View {
    @EnvironmentObject var sb : ScheduleBuilder
    @Binding var selected_schedule : Schedule?
    @Binding var selection : Int
    // let accent_color : Color = Color(red: 0.584, green: 0, blue: 0.11)
    let accent_color : Color = Color.red
    
    var body: some View {
        VStack {
            if sb.courses.count > 0 {
                VStack {
                    Text("YOU CHOSE THE FOLLOWING COURSES")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .background(
                            Rectangle()
                                .frame(width: 500, height: 30, alignment: .center)
                                .foregroundColor(.red)
                        )
                }
                VStack(alignment: .leading) {
                    ForEach(sb.courses, id: \.self) {course in
                        HStack (alignment: .top){
                            Text("\(course.course_id): ").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            Text("\(course.course_name)").fontWeight(.light)
                        }
                    }
                }.padding()
            
                Spacer(minLength: 25)
            }
            if sb.schedules.count > 0 {
                Text("WE BUILT THE FOLLOWING SCHEDULES")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .background(
                        Rectangle()
                            .frame(width: 500, height: 30, alignment: .center)
                            .foregroundColor(.red))
                
                ScrollView {
                    Spacer()
                    SchedulesView(schedules: $sb.schedules, selected_schedule: $selected_schedule, selection : $selection)
                }.offset(x: 0, y: 20)
            } else {
                if sb.courses.count > 0 {
                    Text("The only schedules for your selected courses had a time conflict, no schedules generated")
                        .font(.headline)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.red)
                        .padding()
                        .offset(x: 0, y: -200)
                } else {
                    VStack {
                        Spacer()
                        Text("NOTHING TO SEE HERE")
                            .font(.title)
                            .fontWeight(.black)
                            
                        Text("GO ADD A COURSE OR TWO")
                            .font(.headline)
                            .fontWeight(.light)
                        Spacer()
                    }.padding()
                }
            }
        }.offset(x: 0, y: -20)
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    // let accent_color : Color = Color(red: 0.584, green: 0, blue: 0.11)
    let accent_color : Color = Color.red

    @EnvironmentObject var sb : ScheduleBuilder
    @State var course_input : String = ""
    @State var error_course : String = ""
    @State var selection = 1
    @State var selected_schedule : Schedule? = nil
    
    // State var to manage error in add_course
    @State var add_course_error : Int = 0
    
    func add() {
        add_course_error = sb.add_course(course_input)
        error_course = course_input
        course_input = ""
    }
    
    func remove(_ course_id : String) {
        sb.remove_course(course_id)
    }
    
    func build() {
        sb.build_schedules()
        // selection = 2
    }
    
    func reset() {
        sb.reset_courses()
        sb.reset_schedules()
        selected_schedule = nil
    }
    
    func toggle_save(_ schedule_id : UUID) {
        // get schedule
        sb.toggle_save(schedule_id)
    }
    
    func toggle_calendar(_ schedule_id : UUID) {
        sb.toggle_calendar(schedule_id)
    }

    
    var body: some View {
        TabView(selection: $selection) {
            VStack {
                Spacer()
                Text("Hello Terp!")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .padding(.trailing,160)
                Text("Welcome to Jupiter, a lightweight schedule builder alternative to Venus\n\nOur predicitive ML ranking model (powered by CMSC422) organizes schedules based on the likelihood that they give you a high GPA.\n\nA few notes: This is only Version 0.1.1 of our app. It is not perfect, but it is a step in the right direction, giving paramount importance to accessible UX and faster build times. Like any app, we will work on our bugs and hope to improve for our primary end user — you, the student").fontWeight(.light).padding([.top, .leading, .trailing], 22.5)
                Spacer()
               
                
            }.tabItem {Label("ABOUT", systemImage: "info.circle")}
             .tag(0)
            
            NavigationView {
                ZStack {
                    VStack {
                        TextField("Enter a course id (CMSC436)", text: $course_input)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .position(x: 165, y: -20)
                            .padding([.top, .leading, .trailing], 30)
                        
                        Button(action:add) {
                            Text("ADD COURSE")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .frame(width: 150, height: 30, alignment: .center)
                                        .foregroundColor(.black)
                                )
                        }.offset(x: 0, y: -240)
                         .padding([.top,.bottom], 20.0)
                        
                        HStack {
                            NavigationLink(destination: BuildView(selected_schedule: $selected_schedule, selection: $selection)) {
                                Text("BUILD")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20.0)
                                            .foregroundColor(.yellow)
                                            .frame(width: 75, height: 30, alignment: .center)
                                    )
                            }.simultaneousGesture(TapGesture().onEnded{
                                build()
                            }).padding([.top, .trailing], 50.0)
                    
                            Button(action:reset) {
                                Text("RESET")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20.0)
                                            .foregroundColor(.red)
                                            .frame(width: 75, height: 30, alignment: .center)
                                            
                                    )
                            }.padding(.top, 50.0)
                        }.position(x: 195, y: 200)
                    }
                    
                    ZStack {
                        VStack (alignment: .leading){
                            ForEach(sb.courses.reversed(), id: \.self) { course in
                                HStack {
                                    VStack(alignment: .leading){
                                        Text("\(course.course_id):").fontWeight(.bold) +
                                        Text(" \(course.course_name)").fontWeight(.light)
                                    }.frame(width: 290, alignment: .leading)
                                    
                                        
                                    VStack {
                                        Button {
                                            remove(course.course_id)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .resizable()
                                                .frame(width: 30, height: 30, alignment: .center)
                                                
                                        }
                                    }.frame(width: 30)
                                    
                                }.padding().background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .frame(minWidth: 350, idealWidth: 350, maxWidth: 350, minHeight: 30, idealHeight: 45, maxHeight: 60, alignment: .center)
                                        .foregroundColor(Color(red: 0.93, green: 0.93, blue: 0.93))
                                ).animation(.easeInOut)
                                
                            }
                        }.frame(alignment:.top)
                        
                        if add_course_error > 0 {
                            AddCourseErrorView(course_id: $error_course, add_course_error: $add_course_error)
                        }
                        
                    }
                
                }
            }.tabItem { Label("BUILD", systemImage: "hammer") }
             .tag(1)
            .background(Rectangle().frame(width: 600, height: 1030, alignment: .center).foregroundColor(.red))
                
            VStack {
                Text("SCHEDULE DETAILS")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .background(
                        Rectangle()
                            .frame(width: 500, height: 30, alignment: .center)
                            .foregroundColor(.red))
                    .padding([.top,.bottom], 20)
                
                if selected_schedule != nil {
                    ScrollView {
                        VStack(alignment: .leading) {
                            HStack{
                                Text("\(selected_schedule!.rank).")
                                    .font(.title)
                                    .frame(width:50)
                                    
                                Spacer()
                                Button {
                                    // action is to change the selected schedule to this one, and then pass it into details view
                                    selection = 1
                                } label : {
                                    Text("BACK")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .background(
                                            RoundedRectangle(cornerRadius: 5.0)
                                                .frame(width: 60, height: 20, alignment: .center)
                                                .foregroundColor(.yellow)
                                        )
                                }
                            
                            }.frame(width: 275).padding([.top,.leading,.trailing])
                            VStack(alignment: .leading) {
                                ForEach(selected_schedule!.sections, id: \.self) { section in
                                    VStack (alignment: .leading){
                                        Text("\(section.course_id): \(section.course_name)")
                                            .fontWeight(.bold)
                                            .foregroundColor(.red)
                                        + Text(" | \(section.credits) Credits")
                                            .fontWeight(.light)
                                            .foregroundColor(.red)
                                        if section.prof.count > 0 {
                                            Text("Section \(section.number) | \(section.prof[0])")
                                                .fontWeight(.semibold)
                                                .foregroundColor(.gray)
                                        }
                                        VStack(alignment: .leading){
                                            ForEach(section.times, id: \.self) { meeting in
                                                if meeting.room != "ONLINE" {
                                                    HStack {
                                                        Text("\(meeting.days)").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                                        Text("\(meeting.building) \(meeting.room) | \(meeting.start_time) - \(meeting.end_time)").fontWeight(.light)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        HStack {
                                            Text("Open Seats:").fontWeight(.bold)
                                            Text("\(section.open_seats)")
                                        }
                                        
                                        HStack {
                                            VStack {
                                                Text("Avg. GPA").fontWeight(.bold)
                                                Text("\(NSString(format: "%.2f", section.avg_gpa))").font(.title)
                                            }
                                            Spacer()
                                            VStack {
                                                Text("Prof. Rating").fontWeight(.bold)
                                                Text("\(NSString(format: "%.2f", section.prof_rating))").font(.title)
                                            }
                                            
                                        }.frame(width: 300).padding([.top], 15)
                                    }
                                }.padding()
                            }
                        }
                         .padding()
                         .background(RoundedRectangle(cornerRadius: 20.0)
                                        .foregroundColor(Color(red: 0.93, green: 0.93, blue: 0.93))
                                        .frame(width: 350)
                         )
                    }
                } else {
                    VStack(alignment: .center){
                        Spacer()
                        Text("NOTHING TO SEE HERE")
                            .font(.title)
                            .fontWeight(.black)
                            
                        Text("GO BUILD SOME SCHEDULES \n& SELECT ONE TO VIEW IN DETAIL")
                            .font(.headline)
                            .fontWeight(.light)
                            .multilineTextAlignment(.center)
                        Spacer()
                        
                    }.padding()
                }


            }.tabItem {Label("VIEW", systemImage: "magnifyingglass")}
             .tag(2)
            
            
            VStack {
                Spacer(minLength: 4)
                Text("YOUR BOOKMARKED SCHEDULES")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .background(
                        Rectangle()
                            .frame(width: 500, height: 30, alignment: .center)
                            .foregroundColor(.red))
                    .padding(.bottom, 20)
                if sb.bookmarks.count > 0 {
                    ScrollView {
                        Spacer(minLength: 15)
                        SchedulesView(schedules: $sb.bookmarks, selected_schedule: $selected_schedule, selection: $selection)
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("NOTHING TO SEE HERE")
                            .font(.title)
                            .fontWeight(.black)
                            
                        Text("USE THE SAVE BUTTON TO BOOKMARK A SCHEDULE OR TWO")
                            .font(.headline)
                            .fontWeight(.light)
                        Spacer()
                    }.padding()
                }
                
//                    List {
//                        ForEach(items) { item in
//                            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
//                        }
//                        .onDelete(perform: deleteItems)
//                    }
//                    .toolbar {
//                        #if os(iOS)
//                        EditButton()
//                        #endif
//
//                        Button(action: addItem) {
//                            Label("Add Item", systemImage: "plus")
//                        }
//                    }
            }.tabItem {Label("SAVED", systemImage: "list.dash")}
             .tag(3)
            .padding()
        }.accentColor(accent_color)
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext).environmentObject(ScheduleBuilder())
    }
}
