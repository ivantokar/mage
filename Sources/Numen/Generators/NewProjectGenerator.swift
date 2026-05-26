import Foundation
import Prompt

class NewProjectGenerator {
    private let templateEngine: TemplateEngine
    private let author: String?
    private let company: String?
    private let license: String?
    private let database: String

    init(
        author: String? = nil,
        company: String? = nil,
        license: String? = nil,
        database: String = "postgres"
    ) throws {
        self.author = author
        self.company = company
        self.license = license
        self.database = database
        self.templateEngine = try TemplateEngine()
    }

    func generate(projectName: String, at path: String) throws {
        let config = ProjectConfiguration.vaporConfiguration()

        print("   Creating directory structure...".dim)
        try createDirectories(config.directories, at: path)
        print("  ✅ Directories created".green)

        print("   Generating project files...".dim)
        try generateFiles(config.files, projectName: projectName, at: path)
        print("  ✅ Files generated".green)
    }

    private func createDirectories(_ directories: [String], at basePath: String) throws {
        for directory in directories {
            let fullPath = "\(basePath)/\(directory)"
            try FileManager.default.createDirectory(
                atPath: fullPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }

    private func generateFiles(_ files: [TemplateFile], projectName: String, at basePath: String) throws {
        let resolvedAuthor = author ?? GitConfig.getUserName() ?? ""
        let context: [String: Any] = [
            "projectName": projectName,
            "projectNameLower": projectName.lowercased(),
            "author": resolvedAuthor,
            "company": company ?? "",
            "license": license ?? "MIT",
            "database": database,
            "numenVersion": NumenVersion.current,
        ]

        for file in files {
            let outputPath = "\(basePath)/\(file.path)"
            let content = try templateEngine.render(template: file.template, context: context)
            let dir = (outputPath as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(
                atPath: dir,
                withIntermediateDirectories: true,
                attributes: nil
            )
            try content.write(toFile: outputPath, atomically: true, encoding: .utf8)
            print("  ✅ \(file.path)".green)
        }
    }

    func initializeGit(at path: String) throws {
        print("   Initializing git repository...".dim)

        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["init"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("  ✅ Git initialized".green)
            try? createInitialCommit(at: path)
        } else {
            print("  ⚠️  Git initialization failed (continuing...)".yellow)
        }
    }

    private func createInitialCommit(at path: String) throws {
        let addProcess = Process()
        addProcess.currentDirectoryURL = URL(fileURLWithPath: path)
        addProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        addProcess.arguments = ["add", "."]
        addProcess.standardOutput = Pipe()
        addProcess.standardError = Pipe()
        try addProcess.run()
        addProcess.waitUntilExit()

        let commitProcess = Process()
        commitProcess.currentDirectoryURL = URL(fileURLWithPath: path)
        commitProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        commitProcess.arguments = ["commit", "-m", "Initial project scaffold from Numen"]
        commitProcess.standardOutput = Pipe()
        commitProcess.standardError = Pipe()
        try commitProcess.run()
        commitProcess.waitUntilExit()

        if commitProcess.terminationStatus == 0 {
            print("  ✅ Initial commit created".green)
        }
    }

    func printNextSteps(projectName: String) {
        print()
        print("🎉 Project '\(projectName)' created successfully!".green.bold)
        print()
        print("Next steps:".bold)
        print("  cd \(projectName)")
        print("  swift build")
        print("  swift run")
        print()
        print("Generate your first feature:".bold)
        print("  numen feature User --fields \"name:String,email:String\"")
        print()
    }
}
