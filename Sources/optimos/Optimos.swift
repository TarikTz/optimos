import ArgumentParser

@main
struct Optimos: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "optimos",
        abstract: "Capture. Optimize. Convert. Command-line front end for OptimosCore.",
        version: "0.1.0",
        subcommands: [OptimizeCommand.self, ConvertCommand.self, PresetsCommand.self]
    )
}
