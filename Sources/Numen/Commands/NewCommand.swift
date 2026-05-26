import ArgumentParser
import Foundation
import Prompt

struct NewCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new Numen-managed Vapor project"
    )

    @Argument(help: "The name of the project")
    var projectName: String?

    @Option(name: .long, help: "Author name")
    var author: String?

    @Option(name: .long, help: "Company name")
    var company: String?

    @Option(name: .long, help: "License type (MIT, Apache-2.0, etc.)")
    var license: String?

    @Option(name: .long, help: "Database type (postgres, mysql, sqlite)")
    var database: String?

    @Flag(name: .long, help: "Initialize git repository")
    var git: Bool = false

    @Flag(name: [.short, .long], help: "Interactive mode")
    var interactive: Bool = false

    func run() throws {
        guard let projectName else {
            print("❌ Error: Missing required project name".red)
            print("   Usage: numen new <project-name>")
            throw ExitCode.failure
        }

        guard isValidProjectName(projectName) else {
            print("❌ Invalid project name: '\(projectName)'".red)
            print("   Project names must start with a letter and contain only letters, numbers, and hyphens")
            throw ExitCode.failure
        }

        let projectPath = FileManager.default.currentDirectoryPath + "/\(projectName)"

        if FileManager.default.fileExists(atPath: projectPath) {
            print("❌ Error: Directory '\(projectName)' already exists".red)
            throw ExitCode.failure
        }

        var selectedAuthor = author
        var selectedCompany = company
        var selectedLicense = license
        var selectedDatabase = database ?? "postgres"
        var selectedGit = git

        if interactive {
            print()
            print("Configure your new project:".bold)
            print()

            selectedAuthor = NumenPrompt.ask("Author name", defaultValue: selectedAuthor ?? GitConfig.getUserName())
            selectedCompany = NumenPrompt.ask("Company name", defaultValue: selectedCompany)

            if let dbChoice = NumenPrompt.choose(
                "Select database:",
                options: ["postgres", "mysql", "sqlite"],
                defaultIndex: 0
            ) {
                selectedDatabase = dbChoice
            }

            if let licenseChoice = NumenPrompt.choose(
                "Select license:",
                options: ["MIT", "Apache-2.0", "GPL-3.0", "None"],
                defaultIndex: 0
            ) {
                selectedLicense = licenseChoice == "None" ? nil : licenseChoice
            }

            selectedGit = NumenPrompt.confirm("Initialize git repository?", defaultValue: true)
            print()
        }

        print()
        print("🔮 Numen — Vapor Project Generator".magenta.bold)
        print()
        print("   Project: \(projectName.cyan.bold)")
        print("   Database: \(selectedDatabase.yellow)")
        if let auth = selectedAuthor, !auth.isEmpty {
            print("   Author: \(auth.yellow)")
        }
        print()

        do {
            try FileManager.default.createDirectory(
                atPath: projectPath,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let generator = try NewProjectGenerator(
                author: selectedAuthor,
                company: selectedCompany,
                license: selectedLicense,
                database: selectedDatabase
            )

            try generator.generate(projectName: projectName, at: projectPath)

            if selectedGit {
                try generator.initializeGit(at: projectPath)
            }

            generator.printNextSteps(projectName: projectName)
        } catch {
            print("❌ Error: \(error.localizedDescription)".red)
            try? FileManager.default.removeItem(atPath: projectPath)
            throw ExitCode.failure
        }
    }

    private func isValidProjectName(_ name: String) -> Bool {
        let pattern = "^[A-Za-z][A-Za-z0-9-]*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(location: 0, length: name.utf16.count)
        return regex.firstMatch(in: name, range: range) != nil
    }
}
