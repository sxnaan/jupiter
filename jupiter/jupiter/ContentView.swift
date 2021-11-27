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
    
    func test() {
    }
    
    var body: some View {
        
        ZStack {
            // splash page
            
            VStack {}

            TabView {
                VStack {
                    Text("Hello Terp!")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .padding(.trailing,160)
                    Text("Welcome to Jupiter, a lightweight schedule builder alternative to Venus\n\nOur predicitive ML ranking model (powered by CMSC422) organizes classes based on the likelihood that they give you a high GPA.").fontWeight(.light).padding([.top, .leading, .trailing], 22.5)
                    
                    Spacer()
                        .frame(height: 300.0)
                    
                }.tabItem {Text("ABOUT")}
                
                VStack {
                    
                    Button(action:test) {
                        Text("Test")
                            .font(.headline)
                            .background(
                                RoundedRectangle(cornerRadius: 20.0)
                                    .stroke()
                                    .frame(width: 50, height: 30, alignment: .center)
                            )
                    }.padding(.top, 50.0)
                    
                
                }.tabItem { Text("BUILD") }
                
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
                }.tabItem {Text("HISTORY")}
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
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
