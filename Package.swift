// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "PerfectGSL",
    dependencies: [
      .Package(url: "https://github.com/RockfordWei/GSLApi.git", majorVersion: 1)
    ]
)
