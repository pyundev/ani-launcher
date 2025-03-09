import SwiftUI
import AppKit

struct ContentView: View {
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @FocusState private var isSearchFieldFocused: Bool
    @State private var defaultSuggestions: [SearchResult] = [
        SearchResult(id: UUID(), title: "Applications", subtitle: "Open an application", type: .application, path: ""),
        SearchResult(id: UUID(), title: "Search on Google", subtitle: "Web Search", type: .web, path: "")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("Search...", text: $searchText)
                    .font(.system(size: 16))
                    .textFieldStyle(.plain)
                    .padding(.vertical, 12)
                    .foregroundColor(.white)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        if !searchResults.isEmpty {
                            executeAction(searchResults.first!)
                        } else if !defaultSuggestions.isEmpty && searchText.isEmpty {
                            executeAction(defaultSuggestions.first!)
                        }
                    }
            }
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 0)
            
            // Results list - always visible
            List {
                ForEach(searchText.isEmpty ? defaultSuggestions : searchResults) { result in
                    Button(action: {
                        executeAction(result)
                    }) {
                        HStack {
                            getIconForResult(result)
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading) {
                                Text(result.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(result.subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .padding(.bottom, 16)
        .padding(.bottom, 16)
        .onAppear {
            // Make sure the field has focus when app appears
            setFocusToSearchField()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("FocusSearchField"))) { _ in
            setFocusToSearchField()
        }
        .onChange(of: searchText) { _, _ in
            performSearch(query: searchText)
        }
    }
    
    private func setFocusToSearchField() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSearchFieldFocused = true
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func performSearch(query: String) {
        if query.isEmpty {
            searchResults = []
            return
        }
        
        var results: [SearchResult] = []
        
        // Find applications that match the query
        let apps = findApplications(matching: query)
        results.append(contentsOf: apps)
        
        // Add Finder search option if contains "find" or "file"
        if query.lowercased().contains("find") || query.lowercased().contains("file") {
            results.append(SearchResult(
                id: UUID(),
                title: "Find \"\(query.replacingOccurrences(of: "find ", with: "").replacingOccurrences(of: "file ", with: ""))\" in Finder",
                subtitle: "Open Finder Search",
                type: .file,
                path: query.replacingOccurrences(of: "find ", with: "").replacingOccurrences(of: "file ", with: "")
            ))
        }
        
        // Find folders that match the query
        let folders = findFolders(matching: query)
        results.append(contentsOf: folders)
        
        // Always add Google search option
        results.append(SearchResult(
            id: UUID(),
            title: "Search \"\(query)\" on Google",
            subtitle: "Web Search",
            type: .web,
            path: query
        ))
        
        searchResults = results
    }
    
    func findApplications(matching query: String) -> [SearchResult] {
        var results: [SearchResult] = []
        
        // Get applications in /Applications folder
        let fileManager = FileManager.default
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        
        do {
            let applicationURLs = try fileManager.contentsOfDirectory(at: applicationsURL, includingPropertiesForKeys: nil)
            
            for appURL in applicationURLs {
                if appURL.pathExtension == "app" {
                    let appName = appURL.deletingPathExtension().lastPathComponent
                    
                    // Check if app name contains the query (case insensitive)
                    if appName.lowercased().contains(query.lowercased()) {
                        results.append(SearchResult(
                            id: UUID(),
                            title: appName,
                            subtitle: "Application",
                            type: .application,
                            path: appURL.path
                        ))
                    }
                }
            }
        } catch {
            print("Error finding applications: \(error)")
        }
        
        return results
    }
    
    func findFolders(matching query: String) -> [SearchResult] {
        var results: [SearchResult] = []
        
        // Common folders to search
        let commonFolderPaths = [
            "/Users/\(NSUserName())/Documents",
            "/Users/\(NSUserName())/Downloads",
            "/Users/\(NSUserName())/Desktop",
            "/Users/\(NSUserName())/Pictures"
        ]
        
        // Using underscore to ignore unused variable warning
        _ = FileManager.default
        
        for folderPath in commonFolderPaths {
            let folderURL = URL(fileURLWithPath: folderPath)
            let folderName = folderURL.lastPathComponent
            
            if folderName.lowercased().contains(query.lowercased()) {
                results.append(SearchResult(
                    id: UUID(),
                    title: folderName,
                    subtitle: "Folder",
                    type: .folder,
                    path: folderPath
                ))
            }
        }
        
        return results
    }
    
    func executeAction(_ result: SearchResult) {
        print("Selected: \(result.title)")
        
        switch result.type {
        case .application:
            // Launch the application
            let url = URL(fileURLWithPath: result.path)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            
        case .file, .folder:
            // Open file or folder in Finder
            let url = URL(fileURLWithPath: result.path)
            NSWorkspace.shared.open(url)
            
        case .web:
            // Search on Google using default browser
            if let url = URL(string: "https://www.google.com/search?q=\(result.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? result.path)") {
                NSWorkspace.shared.open(url)
            }
            
        case .claude:
            // Handle claude case
            if let url = URL(string: "https://claude.ai/chat") {
                NSWorkspace.shared.open(url)
            }
        }
        
        // Clear search
        searchText = ""
        
        // Send notification to hide window
        NotificationCenter.default.post(name: NSNotification.Name("ActionExecuted"), object: nil)
    }
    
    func getIconForResult(_ result: SearchResult) -> some View {
        Group {
            if result.type == .application && !result.path.isEmpty {
                // Get actual app icon if possible
                ApplicationIconView(appPath: result.path)
            } else {
                // Fallback to system icons
                Image(systemName: iconForResultType(result.type))
            }
        }
    }
    
    func iconForResultType(_ type: ResultType) -> String {
        switch type {
        case .application:
            return "app.square"
        case .file:
            return "doc"
        case .folder:
            return "folder.fill"
        case .web:
            return "globe"
        case .claude:
            return "bubble.left.and.bubble.right"
        }
    }
}

// New struct to display application icons
struct ApplicationIconView: View {
    let appPath: String
    @State private var iconImage: NSImage?
    
    var body: some View {
        Group {
            if let iconImage = iconImage {
                Image(nsImage: iconImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "app.square")
            }
        }
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        let url = URL(fileURLWithPath: appPath)
        iconImage = NSWorkspace.shared.icon(forFile: url.path)
    }
}
