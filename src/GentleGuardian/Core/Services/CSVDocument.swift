import SwiftUI
import UniformTypeIdentifiers

/// A simple file document wrapping CSV string content for use with `.fileExporter`.
struct CSVDocument: FileDocument {

    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    var csvString: String

    init(csvString: String) {
        self.csvString = csvString
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            csvString = String(data: data, encoding: .utf8) ?? ""
        } else {
            csvString = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = csvString.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
