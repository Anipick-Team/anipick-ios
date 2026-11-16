import ProjectDescription

// Xcode 27.x 마이너 업데이트만 허용 (tech-stack C1).
let tuist = Tuist(project: .tuist(compatibleXcodeVersions: .upToNextMajor("27.0")))
