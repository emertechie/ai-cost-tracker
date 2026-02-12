import Foundation

struct Period: Codable, Equatable, CustomStringConvertible {
    let year: Int
    let month: Int

    var description: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        let date = Calendar(identifier: .gregorian).date(from: comps) ?? Date()
        return formatter.string(from: date)
    }

    /// Returns the period for the current UTC month.
    static func currentUTC() -> Period {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month], from: Date())
        return Period(year: comps.year!, month: comps.month!)
    }

    /// Computes the next reset date (1st of next month at 00:00 UTC).
    var nextResetDate: Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        var comps = DateComponents()
        if month == 12 {
            comps.year = year + 1
            comps.month = 1
        } else {
            comps.year = year
            comps.month = month + 1
        }
        comps.day = 1
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        return cal.date(from: comps)!
    }

    /// Human-readable countdown to the next reset.
    var resetCountdown: String {
        let now = Date()
        let reset = nextResetDate
        guard reset > now else { return "Resets soon" }

        let interval = reset.timeIntervalSince(now)
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600

        if days > 0 {
            return "Resets in \(days)d \(hours)h"
        } else {
            let minutes = (Int(interval) % 3600) / 60
            return "Resets in \(hours)h \(minutes)m"
        }
    }
}
