//
//  ContentView.swift
//  jupiter
//
//  Created by Sinaan Younus on 11/24/21.
//

import SwiftUI
import CoreData

struct AddCourseError : View {
    @Binding var course_id : String
    @Binding var add_course_error : Bool
    var body: some View {
        VStack {
            VStack(alignment:.center){
                Text("ERROR").font(.title).fontWeight(.heavy).foregroundColor(.white)
                Text("COURSE \"\(course_id.uppercased())\" NOT FOUND\nPLEASE TRY AGAIN").font(.headline).fontWeight(.heavy).foregroundColor(.white).multilineTextAlignment(.center)
                Button {
                    add_course_error = false
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

struct DetailsView : View {
    var body: some View {
        Text("details")
    }
}

struct SchedulesView : View {
    @EnvironmentObject var sb : ScheduleBuilder
    @Binding var schedules : [Schedule]
    
    func toggle_save(_ schedule_id : UUID) {
        // get schedule
        sb.toggle_save(schedule_id)
    }
    
    func toggle_calendar(_ schedule_id : UUID) {
        sb.toggle_calendar(schedule_id)
    }
    
    var body : some View {
        VStack(alignment: .leading) {
            ForEach(schedules, id: \.self) { schedule in
                // this is one schedule
                VStack(alignment: .leading) {
                    Text("\(schedule.rank).").font(.title)
                    ForEach(schedule.sections, id: \.self) { section in
                        HStack(alignment: .top){
                            Text("\(section.section_id)").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            VStack(alignment: .leading){
                                ForEach(section.times, id: \.self) { meeting in
                                    Text("\(meeting.days) \(meeting.start_time) - \(meeting.end_time)").fontWeight(.light)
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
                                Image(systemName: schedule.saved.save_img).foregroundColor(.black)
                                Text(schedule.saved.save_text)
                            }
                        }.padding(.trailing, schedule.saved.save_padding)
                        Button {
                            toggle_calendar(schedule.id)
                        } label : {
                            HStack {
                                Image(systemName: schedule.saved.calendar_img).foregroundColor(.black)
                                Text(schedule.saved.calendar_text)
                            }
                        }
                    }
                }.padding()
                 .background(RoundedRectangle(cornerRadius: 20.0)
                                .stroke())
                Spacer(minLength: 20)
            }
        }

    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @EnvironmentObject var sb : ScheduleBuilder
    @State var course_input : String = ""
    @State var error_course : String = ""
    @State private var selection = 1
    
    // State var to manage error in add_course
    @State private var add_course_error : Bool = false
    
    func add() {
        add_course_error = !sb.add_course(course_input)
        error_course = course_input
        course_input = ""
    }
    
    func remove(_ course_id : String) {
        sb.remove_course(course_id)
    }
    
    func build() {
        sb.build_schedules()
        selection = 2
    }
    
    func reset() {
        sb.reset_courses()
        sb.reset_schedules()
    }

    
    var body: some View {
        
        ZStack {
            // splash page
            // VStack

            TabView(selection: $selection) {
                VStack {
                    Text("Hello Terp!")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .padding(.trailing,160)
                    Text("Welcome to Jupiter, a lightweight schedule builder alternative to Venus\n\nOur predicitive ML ranking model (powered by CMSC422) organizes schedules based on the likelihood that they give you a high GPA.").fontWeight(.light).padding([.top, .leading, .trailing], 22.5)
                    
                    Spacer()
                        .frame(height: 300.0)
                    
                }.tabItem {Label("ABOUT", systemImage: "info.circle")}
                 .tag(0)
                
                ZStack {
                    VStack {
                        TextField("Enter a course id (CMSC436)", text: $course_input)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .position(x: 165, y: 100)
                            .padding([.top, .leading, .trailing], 30)
                        
                        Button(action:add) {
                            Text("ADD COURSE")
                                .font(.headline)
                                .background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .stroke()
                                        .frame(width: 150, height: 30, alignment: .center)
                                )
                        }.offset(x: 0, y: -170)
                         .padding([.top,.bottom], 20.0)
                        
                        HStack {
                            Button(action:build) {
                                Text("BUILD")
                                    .font(.headline)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20.0)
                                            .stroke()
                                            .frame(width: 75, height: 30, alignment: .center)
                                    )
                            }.padding([.top, .trailing], 50.0)
                            
                            Button(action:reset) {
                                Text("RESET")
                                    .font(.headline)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20.0)
                                            .stroke()
                                            .frame(width: 75, height: 30, alignment: .center)
                                    )
                            }.padding(.top, 50.0)
                        }.position(x: 195, y: 250)
                    }
                    
                    ZStack {
                        VStack {
                            ForEach(sb.courses, id: \.self) { course in
                                HStack {
                                    Text(course.course_id)
                                        .padding()
                                    Button {
                                        remove(course.course_id)
                                    } label: {
                                        Image("close-circle-regular")
                                            .resizable()
                                            .frame(width: 20, height: 20, alignment: .center)
                                    }.padding(.leading, 50)
                                }.background(
                                    RoundedRectangle(cornerRadius: 20.0)
                                        .stroke()
                                        .frame(width: 200, height: 30, alignment: .center)
                                )
                                
                            }.offset(x: 0, y: 100)
                        }
                        if add_course_error {
                            AddCourseError(course_id: $error_course, add_course_error: $add_course_error)
                        }
                        
                    }
                
                }.tabItem { Label("BUILD", systemImage: "hammer") }
                 .tag(1)
                
                VStack {
                    ScrollView {
                        Spacer(minLength: 25)
                        
                        if sb.courses.count > 0 {
                            Text("YOU CHOSE THE FOLLOWING COURSES")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
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
                                .foregroundColor(.blue)
                            
                            SchedulesView(schedules: $sb.schedules)
                            
                        } else {
                            if sb.courses.count > 0 {
                                Text("The only schedules for your selected courses had a time conflict, no schedules generated")
                                    .font(.headline)
                                    .fontWeight(.light)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                Spacer(minLength: 200)
                                Text("Nothing to see here yet... go build a schedule or two!")
                                    .font(.largeTitle)
                                    .fontWeight(.black)
                                    .multilineTextAlignment(.center)
                                    .padding()
                            }
                        }
                        
                    }
                }.tabItem {Label("VIEW", systemImage: "magnifyingglass")}
                 .tag(2)
                
                VStack {
                    ScrollView {
                        Spacer(minLength: 10)
                        Text("YOUR BOOKMARKED SCHEDULES")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Spacer(minLength: 15)
                        SchedulesView(schedules: $sb.bookmarks)
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
            }
        }
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
