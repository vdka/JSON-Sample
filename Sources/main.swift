
import Foundation
import Dispatch
import JSON

extension URLSession {

    func syncDataTask(with url: URL) -> (Data?, URLResponse?, Error?) {

        let semaphore = DispatchSemaphore(value: 0)

        var data: Data?
        var response: URLResponse?
        var error: Error?

        dataTask(with: url) {
            data = $0
            response = $1
            error = $2
            semaphore.signal()
        }.resume()

        semaphore.wait()

        return (data, response, error)
    }
}

extension URL: JSONInitializable {

    public init(json: JSON) throws {
        switch json {
        case .string(let s):
            guard let url = URL(string: s) else { throw JSON.Error.badValue(json) }
            self = url

        default:
            throw JSON.Error.badValue(json)
        }
    }
}

extension Date: JSONInitializable {

    public init(json: JSON) throws {
        switch json {
        case .double(let d):
            self.init(timeIntervalSince1970: d)

        case .integer(let i):
            self.init(timeIntervalSince1970: TimeInterval(i))

        case .string(let s):
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            guard let date = dateFormatter.date(from: s) else { throw JSON.Error.badValue(json) }
            self.init()
            self = date

        default:
            throw JSON.Error.badValue(json)
        }
    }
}

enum Github {

    struct Repo {
        var name: String
        var fullName: String
        var description: String
        var url: URL
        var isFork: Bool
        var stars: Int
        var createdAt: Date
        var updatedAt: Date
        var pushedAt: Date
    }
}

extension Github.Repo: JSONInitializable {

    init(json: JSON) throws {
        name        = try json.get("name")
        fullName    = try json.get("full_name")
        description = try json.get("description")
        url         = try json.get("html_url")
        isFork      = try json.get("fork")
        stars       = try json.get("stargazers_count")
        createdAt   = try json.get("created_at")
        updatedAt   = try json.get("updated_at")
        pushedAt    = try json.get("pushed_at")
    }
}

let repoUrl = URL(string: "https://api.github.com/repos/vdka/json")!
let (data, response, error) = URLSession.shared.syncDataTask(with: repoUrl)
guard let data = data else { exit(1) }
do {
    let json = try JSON.Parser.parse(data)

    let repo: Github.Repo = try json.get()

    print("\(repo.fullName) has \(repo.stars) stars. Why not make it 1 more!")

} catch {
    print("Some \(error) occurred")
}
