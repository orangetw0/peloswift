
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import Foundation

// PelotonClient class, use to login and get data from the Peloton API
class PelotonClient {
    let PelotonBaseUrl = "https://api.onepeloton.com"
    
    var sessionId: String?
    var userId: String?

    struct Workout {
        let createdAt: Int
        let deviceType: String
        let endTime: Int
        let fitnessDiscipline: String
        let hasPedalingMetrics: Bool
        let id: String
        let metricsType: String
        let name: String
        let platform: String
        let status: String
        let title: String
        let pelotonId: String?
        let workoutType: String
        
        init(json: [String: Any]) {
            self.createdAt = json["created_at"] as? Int ?? 0
            self.deviceType = json["device_type"] as? String ?? ""
            self.endTime = json["end_time"] as? Int ?? 0
            self.fitnessDiscipline = json["fitness_discipline"] as? String ?? ""
            self.hasPedalingMetrics = json["has_pedaling_metrics"] as? Bool ?? false
            self.id = json["id"] as? String ?? ""
            self.metricsType = json["metrics_type"] as? String ?? ""
            self.name = json["name"] as? String ?? ""
            self.platform = json["platform"] as? String ?? ""
            self.status = json["status"] as? String ?? ""
            self.title = json["title"] as? String ?? ""
            self.pelotonId = json["peloton_id"] as? String
            self.workoutType = json["workout_type"] as? String ?? ""
        }
    }

    struct WorkoutDetails  {
        let createdAt: Int
        let deviceType: String
        let endTime: Int
        let fitnessDiscipline: String
        let hasPedalingMetrics: Bool
        let id: String
        let metricsType: String
        let name: String
        let platform: String
        let status: String
        let title: String
        let pelotonId: String?
        let workoutType: String
        let rideId: String
        let rideTitle: String
        let ftp: Int
        let leaderboardRank: Int
        let totalLeaderboardUsers: Int
        
        init(json: [String: Any]) {
            self.createdAt = json["created_at"] as? Int ?? 0
            self.deviceType = json["device_type"] as? String ?? ""
            self.endTime = json["end_time"] as? Int ?? 0
            self.fitnessDiscipline = json["fitness_discipline"] as? String ?? ""
            self.hasPedalingMetrics = json["has_pedaling_metrics"] as? Bool ?? false
            self.id = json["id"] as? String ?? ""
            self.metricsType = json["metrics_type"] as? String ?? ""
            self.name = json["name"] as? String ?? ""
            self.platform = json["platform"] as? String ?? ""
            self.status = json["status"] as? String ?? ""
            self.title = json["title"] as? String ?? ""
            self.pelotonId = json["peloton_id"] as? String
            self.workoutType = json["workout_type"] as? String ?? ""
            self.leaderboardRank = json["leaderboard_rank"] as? Int ?? 0
            self.totalLeaderboardUsers = json["total_leaderboard_users"] as? Int ?? 0

            // getting nested items in JSON
            if let ride = json["ride"] as? [String: Any] {
                self.rideId = ride["id"] as? String ?? ""
                self.rideTitle = ride["title"] as? String ?? ""
            } else {
                self.rideId = ""
                self.rideTitle = ""
            }

            if let ftpInfo = json["ftp_info"] as? [String: Any] {
                self.ftp = ftpInfo["ftp"] as? Int ?? 0
            } else {
                self.ftp = 0
            }
        }
    }

    // struct to store ride details from the getRideDetails function 
    struct RideDetail {
        let id: String
        let title: String
        let description: String

        // add init function to store the data from the JSON, allow empty values
        init(json: [String: Any]) {
            self.id = json["id"] as? String ?? ""
            self.title = json["title"] as? String ?? ""
            self.description = json["description"] as? String ?? ""
        }
    }

    // struct to store PerformanceGraphs using the sample_perfgraph.json as a base the data we need
    // allow empty values if necessary
    struct PerformanceGraphs {
        let averageCadence: [Double]
        let averageResistance: [Double]
        let averageSpeed: [Double]
        let averageWatts: [Double]
        let cadence: [Double]
        let distance: [Double]
        let heartRate: [Double]
        let resistance: [Double]
        let speed: [Double]
        let watts: [Double]

        // add init function to store the data from the JSON, allow empty values
        init(json: [String: Any]) {
            self.averageCadence = json["average_cadence"] as? [Double] ?? []
            self.averageResistance = json["average_resistance"] as? [Double] ?? []
            self.averageSpeed = json["average_speed"] as? [Double] ?? []
            self.averageWatts = json["average_watts"] as? [Double] ?? []
            self.cadence = json["cadence"] as? [Double] ?? []
            self.distance = json["distance"] as? [Double] ?? []
            self.heartRate = json["heart_rate"] as? [Double] ?? []
            self.resistance = json["resistance"] as? [Double] ?? []
            self.speed = json["speed"] as? [Double] ?? []
            self.watts = json["watts"] as? [Double] ?? []
        }
    }

    func auth(usernameOrEmail: String, password: String) {
        let url = URL(string: "\(PelotonBaseUrl)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "username_or_email": usernameOrEmail,
            "password": password
        ]
        
        let bodyData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.sessionId = json["session_id"] as? String
                    self.userId = json["user_id"] as? String
                }
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
    }
    
    func getWorkouts(limit: Int) -> [Workout]? {
        guard let sessionId = sessionId, let userId = userId else {
            print("Error: Missing sessionId or userId")
            return nil
        }
        
        let url = URL(string: "\(PelotonBaseUrl)/api/user/\(userId)/workouts?limit=\(limit)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("peloton_session_id=\(sessionId)", forHTTPHeaderField: "Cookie")
        
        var workouts: [Workout]?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let data = json["data"] as? [[String: Any]] {
                    workouts = data.compactMap { Workout(json: $0) }
                } else {
                    print("Error: Failed to parse JSON")
                }
            } else {
                print("Error: No data received")
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return workouts
    }

    func getWorkout(workoutId: String) -> WorkoutDetails? {
        guard let sessionId = sessionId else {
            print("Error: Missing sessionId")
            return nil
        }
        
        let url = URL(string: "\(PelotonBaseUrl)/api/workout/\(workoutId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("peloton_session_id=\(sessionId)", forHTTPHeaderField: "Cookie")
        
        var workoutDetails: WorkoutDetails?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    workoutDetails = WorkoutDetails(json: json)
                } else {
                    print("Error: Failed to parse JSON")
                }
            } else {
                print("Error: No data received")
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return workoutDetails
    }

    // function called getRideDetails using rideId to store the details into a RideDetail struct
    func getRideDetails(rideId: String) -> RideDetail?{
        // guard statement to check if sessionId exists
        guard let sessionId = sessionId else {
            print("Error: Missing sessionId")
            return nil
        }
        // url to get ride details
        let url = URL(string: "\(PelotonBaseUrl)/api/ride/\(rideId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("peloton_session_id=\(sessionId)", forHTTPHeaderField: "Cookie")
        // variable to store ride details
        var rideDetails: RideDetail?
        // semaphore to wait for response
        let semaphore = DispatchSemaphore(value: 0)
        // data task to get ride details
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    rideDetails = RideDetail(json: json)
                } else {
                    print("Error: Failed to parse JSON")
                }
            } else {
                print("Error: No data received")
            }
            semaphore.signal()
        }
        // resume task and wait for response
        task.resume()
        semaphore.wait()
        // return rideDetails
        return rideDetails
    }

    // function getPerformanceGraphs, allow an interval to be set as well in seconds as a parameter
    func getPerformanceGraphs(workoutId: String, interval: Int) -> PerformanceGraphs? {
        // guard statement to check if sessionId exists
        guard let sessionId = sessionId else {
            print("Error: Missing sessionId")
            return nil
        }
        // url to get performance graphs
        let url = URL(string: "\(PelotonBaseUrl)/api/workout/\(workoutId)/performance_graph?every_n=\(interval)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("peloton_session_id=\(sessionId)", forHTTPHeaderField: "Cookie")
        // variable to store performance graphs
        var performanceGraphs: PerformanceGraphs?
        // semaphore to wait for response
        let semaphore = DispatchSemaphore(value: 0)
        // data task to get performance graphs
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    performanceGraphs = PerformanceGraphs(json: json)
                } else {
                    print("Error: Failed to parse JSON")
                }
            } else {
                print("Error: No data received")
            }
            semaphore.signal()
        }
        // resume task and wait for response
        task.resume()
        semaphore.wait()
        // return performanceGraphs
        return performanceGraphs
    }

    // function checkLoginStatus, takes sessionId and validates against the /auth/check_session endpoint. returns is_authed, is_valid, and ttl 
    func checkLoginStatus() -> [String: Any]? {
        // guard statement to check if sessionId exists
        guard let sessionId = sessionId else {
            print("Error: Missing sessionId")
            return nil
        }
        // url to check login status
        let url = URL(string: "\(PelotonBaseUrl)/auth/check_session")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("peloton_session_id=\(sessionId)", forHTTPHeaderField: "Cookie")
        // variable to store login status
        var loginStatus: [String: Any]?
        // semaphore to wait for response
        let semaphore = DispatchSemaphore(value: 0)
        // data task to get login status
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let data = data {

                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    loginStatus = json
                } else {
                    print("Error: Failed to parse JSON")
                }
            } else {
                print("Error: No data received")
            }
            semaphore.signal()
        }
        // resume task and wait for response
        task.resume()
        semaphore.wait()
        // return loginStatus
        return loginStatus
    }

}

func convertTimestampToReadableDate(_ timestamp: Int) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter.string(from: date)
}

// create PelotonClient instance
let client = PelotonClient()

// read json file to get username and password
let jsonFile = "secret.json"
let jsonData = try! Data(contentsOf: URL(fileURLWithPath: jsonFile))
let json = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
let username = json["username"] as! String
let password = json["password"] as! String

// authenticate using username and password
client.auth(usernameOrEmail: username, password: password)

if let workouts = client.getWorkouts(limit: 10) {
    for workout in workouts {
        if let rideInfo = client.getWorkout(workoutId: workout.id){
            // if the rideId is valid, then try to get the ride details using getRideDetails and print the information to the screen
            if let rideDetails = client.getRideDetails(rideId: rideInfo.rideId){
                print("Workout: \(workout.title)")
                print("Ride: \(rideDetails.title)")
                print("Description: \(rideDetails.description)")
                print("Date: \(convertTimestampToReadableDate(workout.createdAt))")
                // convert duration to minutes or hours
                if (workout.endTime - workout.createdAt) > 3600 {
                    print("Duration: \((workout.endTime - workout.createdAt) / 3600) hours")
                } else {
                    print("Duration: \((workout.endTime - workout.createdAt) / 60) minutes")
                }
                print("Leaderboard Rank: \(rideInfo.leaderboardRank) out of \(rideInfo.totalLeaderboardUsers)")
                print("FTP: \(rideInfo.ftp)")
                print("Workout Type: \(workout.workoutType)")
                print("Fitness Discipline: \(workout.fitnessDiscipline)")
                print("Device Type: \(workout.deviceType)")
                print("Metrics Type: \(workout.metricsType)")
                print("Platform: \(workout.platform)")
                print("Status: \(workout.status)")
                print("Has Pedaling Metrics: \(workout.hasPedalingMetrics)")
                print("Peloton ID: \(workout.pelotonId ?? "")")
                print("Workout ID: \(workout.id)")
                print("")
            }
        }

        // get performance graphs and print them to the screen
        if let performanceGraphs = client.getPerformanceGraphs(workoutId: workout.id, interval: 60){
            print("Average Cadence: \(performanceGraphs.averageCadence)")
            print("Average Resistance: \(performanceGraphs.averageResistance)")
            print("Average Speed: \(performanceGraphs.averageSpeed)")
            print("Average Watts: \(performanceGraphs.averageWatts)")
            print("Cadence: \(performanceGraphs.cadence)")
            print("Distance: \(performanceGraphs.distance)")
            print("Heart Rate: \(performanceGraphs.heartRate)")
            print("Resistance: \(performanceGraphs.resistance)")
            print("Speed: \(performanceGraphs.speed)")
            print("Watts: \(performanceGraphs.watts)")
            print("")
        }
    }
} else {
    print("Failed to get workouts")
}