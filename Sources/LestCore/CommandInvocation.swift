import Foundation

/// Command line arguments split into the command, its values, and its options.
struct CommandInvocation: Equatable {
    var command: String
    var values: [String] = []
    var project: String?
    var here = false
    var all = false
    var json = false
    var remove = false
    var status = false

    init(_ arguments: [String]) throws {
        var remaining = arguments[...]
        guard let command = remaining.popFirst() else { throw CommandError.usage("Missing command.") }
        self.command = command

        var parsesOptions = true
        while let argument = remaining.popFirst() {
            // A note is usually passed as one quoted argument and may well start with a dash
            // ("--verbose is too noisy"), so anything containing a space is text.
            guard parsesOptions, argument.hasPrefix("-"), !argument.contains(" ") else {
                values.append(argument)
                continue
            }

            switch argument {
            case "--":
                parsesOptions = false
            case "--project", "-p":
                guard let name = remaining.popFirst() else {
                    throw CommandError.usage("\(argument) needs a project name.")
                }
                project = name
            case "--here":
                here = true
            case "--all", "-a":
                all = true
            case "--json":
                json = true
            case "--remove":
                remove = true
            case "--status":
                status = true
            default:
                throw CommandError.usage("Unknown option: \(argument)")
            }
        }
    }
}
