import Foundation

enum RepoGitStatus: Equatable, Sendable {
    case unknown
    case clean
    case dirty(changedFiles: Int)
}
