import Foundation

let locationName: String = "六本木"
print("ようこそ" + locationName + "へ！")

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
try safeShell("cd ..")
let result = try safeShell("ls")
print(result)

// 2. リリースノートを作成する