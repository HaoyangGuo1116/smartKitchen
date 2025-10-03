//
//  ContentView.swift
//  KitchenSketch
//
//  Created by Tina on 2025/09/11.
//11
//
//333
import SwiftUI

struct Ingredient: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var amount: String? = nil
}

struct Recipe: Identifiable {
    let id = UUID()
    var title: String
    var category: String
    var prepTime: String
    var difficulty: String
    var ingredients: [Ingredient]
    var steps: [String]
    var lastCooked: String? // e.g. "6 months ago"
    var thumbnail: String?  // system image name for sketch
}

struct FridgeItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: String
    var expiry: Date
}

struct ShoppingItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: String
    var isChecked: Bool = false
}
struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var showOnboarding = true
    
    var body: some View {
        Group {
            if !isLoggedIn {
                AuthFlowView(isLoggedIn: $isLoggedIn, showOnboarding: $showOnboarding)
            } else {
                MainTabView()
            }
        }
    }
}

struct AuthFlowView: View {
    @Binding var isLoggedIn: Bool
    @Binding var showOnboarding: Bool
    
    var body: some View {
        NavigationStack {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
            } else {
                AuthLandingView(isLoggedIn: $isLoggedIn)
            }
        }
    }
}

struct OnboardingView: View {
    var onContinue: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Kitchen Companion")
                .font(.largeTitle).fontWeight(.semibold)
            Text("Track fridge items and expirations, manage recipes, and auto-build shopping lists based on what you plan to cook.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button("Continue") { onContinue() }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 32)
        }
        .padding()
    }
}

struct AuthLandingView: View {
    @Binding var isLoggedIn: Bool
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Welcome")
                .font(.largeTitle).fontWeight(.medium)
            Text("Sign in to sync recipes and fridge inventory across devices.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            VStack(spacing: 12) {
                Button("Log In") { showLogin = true }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                Button("Sign Up") { showSignUp = true }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showLogin) {
            LoginView { isLoggedIn = true }
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView { isLoggedIn = true }
                .presentationDetents([.large])
        }
    }
}

struct LoginView: View {
    var onSuccess: () -> Void
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }
            }
            .navigationTitle("Log In")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { onSuccess() }
                }
            }
        }
    }
}

struct SignUpView: View {
    var onSuccess: () -> Void
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Name", text: $name)
                }
                Section("Account") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                }
                Section(footer: Text("By continuing, you agree to the terms.")) {
                    Button("Create Account") { onSuccess() }
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Sign Up")
        }
    }
}


struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house") }
            RecipeListView()
                .tabItem { Label("Recipes", systemImage: "book") }
            FridgeView()
                .tabItem { Label("Fridge", systemImage: "refrigerator") }
            ShoppingListView()
                .tabItem { Label("Shopping", systemImage: "cart") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
        }
    }
}

//dashboard + navi⬆️

struct DashboardView: View {
    @State private var expiringSoonCount = SampleData.fridgeItems.filter {
        Calendar.isDateInNextNDays($0.expiry, days: 3)
    }.count

    
    var body: some View {
        NavigationStack {
            List {
                Section("Quick Access") {
                    NavigationLink("Recipes", destination: RecipeListView())
                    NavigationLink("Fridge", destination: FridgeView())
                    NavigationLink("Shopping List", destination: ShoppingListView())
                }
                Section("Today") {
                    HStack {
                        Text("Items expiring soon")
                        Spacer()
                        Text("\(expiringSoonCount)")
                            .fontWeight(.semibold)
                    }
                    NavigationLink {
                        RecipeDetailView(recipe: SampleData.basqueCheesecake)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tonight’s Suggestion")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Basque Cheesecake")
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle("Kitchen")
        }
    }
}

//recipes

struct RecipeListView: View {
    @State private var query = ""
    @State private var selectedCategory = "All"
    private let categories = ["All", "Breakfast", "Dinner", "Dessert"]
    private var recipes: [Recipe] {
        let base = SampleData.recipes
        let filteredByCategory = selectedCategory == "All" ? base : base.filter { $0.category == selectedCategory }
        if query.isEmpty { return filteredByCategory }
        return filteredByCategory.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Search recipes", text: $query)
                        .textFieldStyle(.roundedBorder)
                    Menu(selectedCategory) {
                        ForEach(categories, id: \.self) { c in
                            Button(c) { selectedCategory = c }
                        }
                    }
                }
                .padding(.horizontal)
                List(recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        HStack {
                            Image(systemName: recipe.thumbnail ?? "book")
                                .frame(width: 32)
                            VStack(alignment: .leading) {
                                Text(recipe.title).font(.headline)
                                Text("\(recipe.prepTime) • \(recipe.difficulty)")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let last = recipe.lastCooked {
                                Text("Last cooked \(last)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Add") { AddRecipeSketchView() }
                }
            }
        }
    }
}

struct RecipeDetailView: View {
    var recipe: Recipe
    @State private var selectedStepsIndex: Int? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(recipe.title)
                    .font(.title).fontWeight(.semibold)
                HStack(spacing: 16) {
                    Label(recipe.prepTime, systemImage: "clock")
                    Label(recipe.difficulty, systemImage: "chart.line.uptrend.xyaxis")
                }
                .foregroundStyle(.secondary)
                
                Divider()
                
                Text("Ingredients")
                    .font(.headline)
                ForEach(recipe.ingredients) { ing in
                    HStack {
                        Circle().frame(width: 8, height: 8)
                            .foregroundStyle(.secondary)
                        Text(ing.name + (ing.amount.map { " – \($0)" } ?? ""))
                        Spacer()
                        // Link to fridge concept sketch
                        NavigationLink {
                            FridgeView()
                        } label: {
                            Image(systemName: "refrigerator")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Divider()
                
                Text("Steps")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { idx, step in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Step \(idx + 1)")
                                    .font(.subheadline).fontWeight(.semibold)
                                Spacer()
                                Button {
                                    selectedStepsIndex = idx
                                } label: {
                                    Text("Open")
                                }
                            }
                            Text(step)
                                .foregroundStyle(.primary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.2)))
                    }
                }
                
                Button {
                    // Placeholder for cooking mode
                } label: {
                    Text("Start Cooking")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddRecipeSketchView: View {
    @State private var title = ""
    @State private var category = "Dinner"
    @State private var prepTime = "45 min"
    @State private var difficulty = "Medium"
    @State private var note = ""
    
    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Title", text: $title)
                Picker("Category", selection: $category) {
                    Text("Breakfast").tag("Breakfast")
                    Text("Dinner").tag("Dinner")
                    Text("Dessert").tag("Dessert")
                }
                TextField("Prep Time", text: $prepTime)
                Picker("Difficulty", selection: $difficulty) {
                    Text("Easy").tag("Easy")
                    Text("Medium").tag("Medium")
                    Text("Hard").tag("Hard")
                }
            }
            Section("Notes") {
                TextField("Optional", text: $note, axis: .vertical)
            }
            Section {
                Button("Save (Sketch)") {}
            }
        }
        .navigationTitle("Add Recipe")
    }
}


//frige view
struct FridgeView: View {
    @State private var items = SampleData.fridgeItems
    @State private var showAdd = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    HStack {
                        StatusDot(color: color(for: item.expiry))
                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text("Qty: \(item.quantity)")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.expiry, style: .date)
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    items.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Fridge")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { showAdd = true }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddFridgeItemView { newItem in
                    items.append(newItem)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private func color(for date: Date) -> Color {
        if Calendar.current.isDateInPast(date) { return .red }
        if Calendar.current.isDateWithinDays(date, days: 3) { return .yellow }
        return .green
    }
}

struct StatusDot: View {
    var color: Color
    var body: some View {
        Circle().fill(color).frame(width: 10, height: 10)
    }
}

struct AddFridgeItemView: View {
    var onAdd: (FridgeItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = ""
    @State private var expiry = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Quantity", text: $quantity)
                DatePicker("Expiry", selection: $expiry, displayedComponents: .date)
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onAdd(FridgeItem(name: name, quantity: quantity, expiry: expiry))
                        dismiss()
                    }.disabled(name.isEmpty || quantity.isEmpty)
                }
            }
        }
    }
}

//shopping section
struct ShoppingListView: View {
    @State private var items: [ShoppingItem] = SampleData.shopping
    @State private var showAdd = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($items) { $item in
                    HStack {
                        Button {
                            item.isChecked.toggle()
                        } label: {
                            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)
                        Text(item.name)
                        Spacer()
                        Text(item.quantity).foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexSet in
                    items.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Shopping")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Add") { showAdd = true }
                    Menu("Actions") {
                        Button("Generate from Selected Recipes") {
                            // Placeholder for future logic
                        }
                        Button("Remove Checked") {
                            items.removeAll { $0.isChecked }
                        }
                        Button("Share") {
                            // Placeholder for share
                        }
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddShoppingItemView { newItem in
                    items.append(newItem)
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct AddShoppingItemView: View {
    var onAdd: (ShoppingItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = "1"
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Item", text: $name)
                TextField("Quantity", text: $quantity)
            }
            .navigationTitle("Add to List")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onAdd(ShoppingItem(name: name, quantity: quantity))
                        dismiss()
                    }.disabled(name.isEmpty)
                }
            }
        }
    }
}

//profile + settings
struct ProfileView: View {
    @State private var vegetarian = false
    @State private var allergies = ""
    @State private var units = "Metric"
    let unitOptions = ["Metric", "US Customary"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle("Vegetarian", isOn: $vegetarian)
                    TextField("Allergies", text: $allergies)
                    Picker("Units", selection: $units) {
                        ForEach(unitOptions, id: \.self) { Text($0) }
                    }
                }
                Section("Account") {
                    NavigationLink("Manage Subscription") { Text("Sketch") }
                    NavigationLink("Privacy") { Text("Sketch") }
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("0.1 (Sketch)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}


enum SampleData {
    static let basqueCheesecake = Recipe(
        title: "Basque Cheesecake",
        category: "Dessert",
        prepTime: "60 min",
        difficulty: "Medium",
        ingredients: [
            Ingredient(name: "Cream Cheese", amount: "600 g"),
            Ingredient(name: "Sugar", amount: "180 g"),
            Ingredient(name: "Eggs", amount: "4"),
            Ingredient(name: "Heavy Cream", amount: "240 ml"),
            Ingredient(name: "Cake Flour", amount: "20 g"),
            Ingredient(name: "Vanilla Extract", amount: "1 tsp")
        ],
        steps: [
            "Preheat oven to 230°C. Line a springform pan with parchment, ensuring tall sides.",
            "Beat cream cheese and sugar until smooth.",
            "Add eggs one by one, then heavy cream and vanilla. Sift in flour and mix just to combine.",
            "Pour batter into pan. Bake until deeply browned on top and just set in center.",
            "Cool completely. The center will sink slightly as it sets."
        ],
        lastCooked: "6 months ago",
        thumbnail: "flame"
    )
    
    static let sampleDinner = Recipe(
        title: "Garlic Butter Chicken",
        category: "Dinner",
        prepTime: "30 min",
        difficulty: "Easy",
        ingredients: [
            Ingredient(name: "Chicken Thighs", amount: "600 g"),
            Ingredient(name: "Garlic", amount: "4 cloves"),
            Ingredient(name: "Butter", amount: "40 g"),
            Ingredient(name: "Parsley", amount: "A handful")
        ],
        steps: [
            "Season chicken and sear until golden.",
            "Add butter and garlic, baste to finish.",
            "Rest and garnish with chopped parsley."
        ],
        lastCooked: nil,
        thumbnail: "fork.knife"
    )
    
    static let recipes: [Recipe] = [basqueCheesecake, sampleDinner]
    
    static let fridgeItems: [FridgeItem] = [
        FridgeItem(name: "Beef", quantity: "500 g", expiry: Calendar.current.date(byAdding: .day, value: 2, to: Date())!),
        FridgeItem(name: "Milk", quantity: "1 L", expiry: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
        FridgeItem(name: "Eggs", quantity: "12", expiry: Calendar.current.date(byAdding: .day, value: 10, to: Date())!)
    ]
    
    static let shopping: [ShoppingItem] = [
        ShoppingItem(name: "Heavy Cream", quantity: "1"),
        ShoppingItem(name: "Vanilla Extract", quantity: "1"),
        ShoppingItem(name: "Parsley", quantity: "1 bunch")
    ]
}

extension Calendar {
    func isDateWithinDays(_ date: Date, days: Int) -> Bool {
        guard let end = self.date(byAdding: .day, value: days, to: Date()) else { return false }
        return (date >= Date()) && (date <= end)
    }
    func isDateInPast(_ date: Date) -> Bool {
        date < Date()
    }
    static func isDateInNextNDays(_ date: Date, days: Int) -> Bool {
        Calendar.current.isDateWithinDays(date, days: days)
    }
}

#Preview {
    ContentView()
}
