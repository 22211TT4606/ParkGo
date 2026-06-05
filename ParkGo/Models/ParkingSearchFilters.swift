import Foundation

struct ParkingSearchFilters: Hashable {
    var onlyEVCharging = false
    var onlyOvernight = false
    var underTwenty = false
    var onlyAvailable = false

    var summary: String {
        var values: [String] = []
        if onlyEVCharging { values.append("EV") }
        if onlyOvernight { values.append("Overnight") }
        if underTwenty { values.append("<20k") }
        if onlyAvailable { values.append("Available") }
        return values.isEmpty ? "No filter" : values.joined(separator: ", ")
    }
}

