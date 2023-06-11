import Foundation

// - seealso: https://stackoverflow.com/a/50035059/18519539
@discardableResult // Add to suppress warnings when you don't want/need a result
func safeShell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh") //<--updated
    task.standardInput = nil

    try task.run() //<--updated
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

// 1. タグを打つ
let envArgs = ProcessInfo.processInfo.environment
precondition(envArgs["TAG"] != nil)

let tag = envArgs["TAG"]!
print(tag)

// FIXME: cd しているけどディレクトリが変わっていない。。。
try safeShell("cd .. && git tag \(tag) && git push origin \(tag)")

// 2. リリースノートを作成する
enum HttpMethod: String {
    case post = "POST"
}

protocol Request {
    var baseURL: URL { get }
    var method: HttpMethod { get }
    var path: String { get }
    var headerFields: [String: String]? { get }
    var body: [String: Any]? { get }
}

protocol GitHubRequest: Request {}

extension GitHubRequest {
    var baseURL: URL {
        return URL(string: "https://api.github.com")!
    }

    var headerFields: [String: String]? {
        return [
            "Accept": "application/vnd.github+json",
            "Authorization": "Bearer \(envArgs["GITHUB_TOKEN"]!)",
            "X-GitHub-Api-Version": "2022-11-28"
        ]
    }
}

struct GenerateReleaseNote: GitHubRequest {
    var method: HttpMethod = .post
    var path = "/repos/kamimi01/FastlaneTest/releases"
    var body: [String: Any]? = [
        "tag_name": tag, 
        "name": tag,
        "body": tag,
        "prerelease": true
    ]
}

let releaseNoteRequest = GenerateReleaseNote()
let httpBody = try! JSONSerialization.data(withJSONObject: releaseNoteRequest.body, options: [])

let url = releaseNoteRequest.baseURL.appendingPathComponent(releaseNoteRequest.path)
var request = URLRequest(url: url)
request.httpMethod = releaseNoteRequest.method.rawValue
request.allHTTPHeaderFields = releaseNoteRequest.headerFields
request.httpBody = httpBody

do {
    let (data, urlResponse) = try await URLSession.shared.data(for: request)
    let response = urlResponse as! HTTPURLResponse
    print(response)
} catch {
    print(error)
}