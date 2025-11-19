import Foundation
import Testing

@testable import SharedUtilities

@Suite("ProcessRunner Tests")
struct ProcessRunnerTests {
    // MARK: - Command Exists Tests

    @Test("commandExists returns true for valid commands")
    func commandExistsValid() {
        #expect(ProcessRunner.commandExists("echo"))
        #expect(ProcessRunner.commandExists("ls"))
        #expect(ProcessRunner.commandExists("pwd"))
    }

    @Test("commandExists returns false for invalid commands")
    func commandExistsInvalid() {
        #expect(!ProcessRunner.commandExists("nonexistent-command-xyz"))
        #expect(!ProcessRunner.commandExists("totally-fake-command-123"))
    }

    // MARK: - Run Command Tests

    @Test("run succeeds with exit code 0 for successful command")
    func runSuccessfulCommand() throws {
        let exitCode = try ProcessRunner.run("echo", arguments: ["test"])
        #expect(exitCode == 0)
    }

    @Test("run succeeds with exit code 0 for true command")
    func runTrueCommand() throws {
        let exitCode = try ProcessRunner.run("true")
        #expect(exitCode == 0)
    }

    @Test("run returns non-zero exit code for false command")
    func runFalseCommand() throws {
        let exitCode = try ProcessRunner.run("false")
        #expect(exitCode != 0)
    }

    @Test("run throws ProcessError for nonexistent command")
    func runNonexistentCommand() {
        #expect(throws: ProcessError.self) {
            try ProcessRunner.run("nonexistent-command-xyz")
        }
    }

    @Test("run passes arguments correctly")
    func runWithArguments() throws {
        // Create a temp file to test with
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: testFile) }

        // Use touch to create a file
        let exitCode = try ProcessRunner.run("touch", arguments: [testFile.path])
        #expect(exitCode == 0)

        // Verify file was created
        #expect(FileManager.default.fileExists(atPath: testFile.path))
    }

    @Test("run works with working directory")
    func runWithWorkingDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let exitCode = try ProcessRunner.run(
            "pwd",
            arguments: [],
            workingDirectory: tempDir,
        )
        #expect(exitCode == 0)
    }

    @Test("run works with absolute path executable")
    func runAbsolutePathExecutable() throws {
        let exitCode = try ProcessRunner.run("/bin/echo", arguments: ["test"])
        #expect(exitCode == 0)
    }

    // MARK: - ProcessError Tests

    @Test("ProcessError commandNotFound has correct description")
    func processErrorCommandNotFound() {
        let error = ProcessError.commandNotFound("fake-cmd")
        #expect(error.errorDescription?.contains("fake-cmd") == true)
        #expect(error.errorDescription?.contains("Command not found") == true)
    }

    @Test("ProcessError executionFailed has correct description")
    func processErrorExecutionFailed() {
        let error = ProcessError.executionFailed(1, "test-command")
        #expect(error.errorDescription?.contains("test-command") == true)
        #expect(error.errorDescription?.contains("exit code: 1") == true)
    }
}
