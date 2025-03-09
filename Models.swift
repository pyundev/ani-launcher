import Foundation

struct SearchResult: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String
    let type: ResultType
    let path: String
}

enum ResultType {
    case application
    case file
    case folder
    case web
    case claude
}
