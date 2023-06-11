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

try safeShell("cd .. && git tag \(tag) && git push origin \(tag)")
let result = try safeShell("git log --oneline")
print(result)

// 2. リリースノートを作成する
let url = URL(string: "https://api.github.com/repos/kamimi01/FastlaneTest/releases")!
let headers = [
    "Accept": "application/vnd.github+json",
    "Authorization": "Bearer \(envArgs["GITHUB_TOKEN"]!)",
    "X-GitHub-Api-Version": "2022-11-28"
]

let data: [String: Any] = [
    "tag_name": tag, 
    "name": tag,
    "body": tag,
    "prerelease": true
]
let httpBody = try! JSONSerialization.data(withJSONObject: data, options: [])

var request = URLRequest(url: url)
request.httpMethod = "POST"
request.allHTTPHeaderFields = headers
request.httpBody = httpBody

do {
    let (data, urlResponse) = try await URLSession.shared.data(for: request)
    let response = urlResponse as! HTTPURLResponse
    print(response)
} catch {
    print(error)
}