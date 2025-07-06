import Foundation
import CoreLocation

struct SolarCalculator {
    static func solarElevation(for date: Date, latitude: Double, longitude: Double) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)

        let day = Double(components.day ?? 1)
        let month = Double(components.month ?? 1)
        let year = Double(components.year ?? 2000)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)

        // Convert time to UTC fractional hour
        let timeUTC = hour + minute / 60 + second / 3600

        // Julian day
        let jd = julianDay(year: year, month: month, day: day, hour: timeUTC)
        let t = (jd - 2451545.0) / 36525.0

        // Sun coordinates
        let L0 = fmod(280.46646 + t*(36000.76983 + t*0.0003032), 360)
        let M = 357.52911 + t*(35999.05029 - 0.0001537*t)
        let e = 0.016708634 - t*(0.000042037 + 0.0000001267*t)
        let C = (1.914602 - t*(0.004817 + 0.000014*t)) * sin(deg2rad(M))
              + (0.019993 - 0.000101*t) * sin(deg2rad(2*M))
              + 0.000289 * sin(deg2rad(3*M))
        let trueLongitude = L0 + C
        let apparentLongitude = trueLongitude - 0.00569 - 0.00478 * sin(deg2rad(125.04 - 1934.136*t))

        let epsilon0 = 23.439291 - 0.0130042*t
        let epsilon = epsilon0 + 0.00256 * cos(deg2rad(125.04 - 1934.136*t))

        let declination = rad2deg(asin(sin(deg2rad(epsilon)) * sin(deg2rad(apparentLongitude))))

        let timeOffset = 4*longitude - equationOfTime(L0: L0, e: e, M: M)
        let trueSolarTime = fmod(timeUTC*60 + timeOffset + 1440, 1440) / 4.0
        let hourAngle = (trueSolarTime < 0 ? trueSolarTime + 180 : trueSolarTime - 180)

        let altitude = rad2deg(asin(
            sin(deg2rad(latitude)) * sin(deg2rad(declination)) +
            cos(deg2rad(latitude)) * cos(deg2rad(declination)) * cos(deg2rad(hourAngle))
        ))

        return altitude
    }

    private static func julianDay(year: Double, month: Double, day: Double, hour: Double) -> Double {
        var y = year
        var m = month
        if m <= 2 {
            y -= 1
            m += 12
        }
        let A = floor(y/100)
        let B = 2 - A + floor(A/4)
        let JD = floor(365.25*(y+4716)) + floor(30.6001*(m+1)) + day + B - 1524.5 + hour/24
        return JD
    }

    private static func equationOfTime(L0: Double, e: Double, M: Double) -> Double {
        let y = tan(deg2rad(23.44/2)) * tan(deg2rad(23.44/2))
        return 4 * rad2deg(
            y*sin(2*deg2rad(L0)) -
            2*e*sin(deg2rad(M)) +
            4*e*y*sin(deg2rad(M))*cos(2*deg2rad(L0)) -
            0.5*y*y*sin(4*deg2rad(L0)) -
            1.25*e*e*sin(2*deg2rad(M))
        )
    }

    private static func deg2rad(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }

    private static func rad2deg(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
}
