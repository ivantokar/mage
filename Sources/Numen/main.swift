import ArgumentParser
import Foundation

struct Numen: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "numen",
        abstract: "A CLI tool for generating server-side Swift DDD architecture components",
        version: NumenVersion.current,
        subcommands: [
            NewCommand.self,
            EntityCommand.self,
            ValueObjectCommand.self,
            AggregateRootCommand.self,
            DomainEventCommand.self,
            ServiceCommand.self,
            RepositoryCommand.self,
            UseCaseCommand.self,
            DTOCommand.self,
            ControllerCommand.self,
            RouteCommand.self,
            MiddlewareCommand.self,
            MigrationCommand.self,
            RelationshipCommand.self,
            SeederCommand.self,
            FeatureCommand.self,
            TestCommand.self,
            AuthCommand.self,
            DocsCommand.self,
            FluentModelCommand.self,
            HTTPRequestCommand.self,
            HTTPResponseCommand.self,
        ],
        defaultSubcommand: nil
    )
}

Numen.main()
