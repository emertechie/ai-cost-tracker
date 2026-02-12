#!/usr/bin/env swift
import Foundation

struct UsageResponse: Codable {
    let usageItems: [UsageItem]
}

struct UsageItem: Codable {
    let product: String?
    let sku: String?
    let model: String?
    let grossQuantity: Double?
    let discountQuantity: Double?
    let netQuantity: Double?
    let grossAmount: Double?
    let discountAmount: Double?
    let netAmount: Double?
}

struct Snapshot {
    let includedConsumed: Int
    let billedQuantity: Int
    let billedAmount: Double
}

enum Phase0Error: Error, CustomStringConvertible {
    case missingPath
    case fileNotFound(String)
    case decodeFailure(String)

    var description: String {
        switch self {
        case .missingPath:
            return "Usage: scripts/phase0_verify.swift <path-to-json> [included-allowance]"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .decodeFailure(let message):
            return "Failed to decode response JSON: \(message)"
        }
    }
}

func aggregate(_ response: UsageResponse) -> Snapshot {
    let includedConsumed = response.usageItems.reduce(0) { partialResult, item in
        partialResult + Int((item.discountQuantity ?? 0).rounded())
    }

    let billedQuantity = response.usageItems.reduce(0) { partialResult, item in
        partialResult + Int((item.netQuantity ?? 0).rounded())
    }

    let billedAmount = response.usageItems.reduce(0.0) { partialResult, item in
        partialResult + (item.netAmount ?? 0.0)
    }

    return Snapshot(
        includedConsumed: includedConsumed,
        billedQuantity: billedQuantity,
        billedAmount: billedAmount
    )
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    throw Phase0Error.missingPath
}

let path = args[1]
let allowance = (args.count >= 3 ? Int(args[2]) : nil) ?? 300

guard FileManager.default.fileExists(atPath: path) else {
    throw Phase0Error.fileNotFound(path)
}

let data = try Data(contentsOf: URL(fileURLWithPath: path))

let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .useDefaultKeys

let response: UsageResponse
do {
    response = try decoder.decode(UsageResponse.self, from: data)
} catch {
    throw Phase0Error.decodeFailure(String(describing: error))
}

let snapshot = aggregate(response)
let percent = allowance > 0 ? (Double(snapshot.includedConsumed) / Double(allowance)) * 100.0 : 0.0

print("File: \(path)")
print("Included consumed: \(snapshot.includedConsumed) / \(allowance) (\(String(format: "%.2f", percent))%)")
print("Billed amount (MTD): $\(String(format: "%.4f", snapshot.billedAmount))")
print("Billed premium requests: \(snapshot.billedQuantity)")
