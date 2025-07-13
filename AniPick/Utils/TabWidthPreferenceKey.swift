struct TabWidthPreferenceKey: PreferenceKey {
    static var defaultValue: [SearchTab: CGFloat] = [:]
    static func reduce(value: inout [SearchTab: CGFloat], nextValue: () -> [SearchTab: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}