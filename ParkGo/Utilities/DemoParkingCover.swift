import Foundation

enum DemoParkingCover: String, CaseIterable {
    case saigonCentre = "saigon-centre"
    case takashimaya = "takashimaya"
    case landmark81 = "landmark-81"
    case thisoSala = "thiso-sala"
    case crescentMall = "crescent-mall"
    case tsnDomestic = "tsn-domestic"

    var title: String {
        switch self {
        case .saigonCentre:
            return "Saigon Centre"
        case .takashimaya:
            return "Takashimaya"
        case .landmark81:
            return "Landmark 81"
        case .thisoSala:
            return "Thiso Sala"
        case .crescentMall:
            return "Crescent Mall"
        case .tsnDomestic:
            return "Tan Son Nhat"
        }
    }
}
