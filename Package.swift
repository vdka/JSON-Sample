import PackageDescription

let package = Package(
    name: "JSON-Sample",
    dependencies: [
        .Package(url: "https://github.com/vdka/json", majorVersion: 0, minor: 16)
    ]
)
