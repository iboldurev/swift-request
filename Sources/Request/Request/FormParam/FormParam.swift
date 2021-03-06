//
//  FormParam.swift
//  
//
//  Created by brennobemoura on 16/11/20.
//

import Foundation

public protocol FormParam: RequestParam {
    func buildData(_ data: inout Data, with boundary: String)
}

public extension FormParam {
    func buildParam(_ request: inout URLRequest) {
        let boundary = self.boundary
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()
        buildData(&data, with: boundary)

        if !data.isEmpty {
            data.append(footer(boundary))
        }

        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        request.httpBody = data
    }
}

internal extension FormParam {
    private var random: UInt32 {
        .random(in: .min ... .max)
    }

    private var boundary: String {
        String(format: "request.boundary.%08x%08x", random, random)
    }

    var breakLine: String {
        "\r\n"
    }

    func header(_ boundary: String) -> Data {
        .init("--\(boundary)\(breakLine)".utf8)
    }

    var middle: Data {
        .init("\(breakLine)".utf8)
    }

    func footer(_ boundary: String) -> Data {
        .init("\(breakLine)--\(boundary)--\(breakLine)".utf8)
    }

    func disposition<S>(_ fileName: S, withType mediaType: MediaType) -> Data where S: StringProtocol {
        let name: String
        if fileName.contains(".") {
            name = fileName
                .split(separator: ".")
                .dropLast()
                .joined(separator: ".")
        } else {
            name = "\(fileName)"
        }

        var contents = Data()

        contents.append(Data("Content-Disposition: form-data; name=\"\(name)\";".utf8))
        contents.append(Data("filename=\"\(fileName)\"".utf8))
        contents.append(Data(breakLine.utf8))

        contents.append(Data("Content-Type: \(mediaType)".utf8))
        contents.append(Data(breakLine.utf8))

        return contents
    }

    func disposition<S>(_ name: S) -> Data where S: StringProtocol {
        Data("Content-Disposition: form-data; name=\"\(name)\"\(breakLine)".utf8)
    }
}
