import Foundation
import Testing
@testable import OptimosCore

@Suite struct ExternalToolTests {
    @Test func pipesInputThroughAProcess() throws {
        let tool = ExternalTool(name: "cat", searchPaths: ["/bin"])
        let input = Data((0..<500_000).map { UInt8($0 % 251) })  // larger than a pipe buffer
        let result = try tool.run([], input: input)
        #expect(result.status == 0)
        #expect(result.output == input)
    }

    @Test func missingToolThrowsToolMissing() {
        let tool = ExternalTool(name: "definitely-not-a-tool", searchPaths: ["/bin"])
        #expect(throws: OptimosError.toolMissing("definitely-not-a-tool")) {
            try tool.run([], input: Data())
        }
    }

    @Test func toolExitingBeforeReadingStdinDoesNotCrash() throws {
        let tool = ExternalTool(name: "true", searchPaths: ["/usr/bin"])
        let input = Data(count: 1_000_000)
        let result = try tool.run([], input: input)
        #expect(result.status == 0)
        #expect(result.output.isEmpty)
    }

    // Callers block a cooperative thread inside run(). With more concurrent runs than cores the
    // stdin/stdout pumps must still get threads, or every tool waits on stdin forever.
    @Test(.timeLimit(.minutes(1)))
    func manyConcurrentRunsDoNotStarve() async throws {
        let input = Data((0..<200_000).map { UInt8($0 % 251) })  // larger than a pipe buffer
        let runs = ProcessInfo.processInfo.activeProcessorCount * 3
        let ok = try await withThrowingTaskGroup(of: Bool.self) { group in
            for _ in 0..<runs {
                group.addTask { try ExternalTool(name: "cat", searchPaths: ["/bin"]).run([], input: input).output == input }
            }
            return try await group.reduce(0) { $0 + ($1 ? 1 : 0) }
        }
        #expect(ok == runs)
    }
}
