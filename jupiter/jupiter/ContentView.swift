//
//  ContentView.swift
//  jupiter
//
//  Created by Sinaan Younus on 11/24/21.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    @EnvironmentObject var sb : ScheduleBuilder
    @State var course_input : String = ""
    @State private var selection = 1
    
    func add() {
        sb.add_course(course_input)
        course_input = ""
    }
    
    func remove(_ course_id : String) {
        sb.remove_course(course_id)
    }
    
    func print() {
        sb.build_schedules()
        sb.print_schedules()
    }
    
    func reset() {
        sb.reset_courses()
    }
    
    var body: some View {
        
        ZStack {
            // splash page
            
            VStack {}

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
                            Button(action:print) {
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
                
                }.tabItem { Label("BUILD", systemImage: "hammer") }
                 .tag(1)
                
                VStack {
                    ScrollView {
                        Text("You chose the following classes:\n\nHere are your schedules")
                    }
                }.tabItem {Label("VIEW", systemImage: "magnifyingglass")}
                 .tag(2)
                 .padding()
                
                VStack {
                    List {
                        ForEach(items) { item in
                            Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .toolbar {
                        #if os(iOS)
                        EditButton()
                        #endif
            
                        Button(action: addItem) {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
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
