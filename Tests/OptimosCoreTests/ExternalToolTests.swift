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
}
