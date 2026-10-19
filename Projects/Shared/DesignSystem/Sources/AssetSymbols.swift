// 이 파일은 Scripts/generate_asset_symbols.sh가 만든다. 직접 고치지 않는다.
// swift-format-ignore-file

import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
nonisolated private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
nonisolated private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AnipickBlackColor" asset catalog color resource.
    nonisolated public static let anipickBlack = DeveloperToolsSupport.ColorResource(name: "AnipickBlackColor", bundle: resourceBundle)

    /// The "AnipickPrimaryColor" asset catalog color resource.
    nonisolated public static let anipickPrimary = DeveloperToolsSupport.ColorResource(name: "AnipickPrimaryColor", bundle: resourceBundle)

    /// The "AnipickSecondaryColor" asset catalog color resource.
    nonisolated public static let anipickSecondary = DeveloperToolsSupport.ColorResource(name: "AnipickSecondaryColor", bundle: resourceBundle)

    /// The "BackgroundColor" asset catalog color resource.
    nonisolated public static let background = DeveloperToolsSupport.ColorResource(name: "BackgroundColor", bundle: resourceBundle)

    /// The "Gray4Color" asset catalog color resource.
    nonisolated public static let gray4 = DeveloperToolsSupport.ColorResource(name: "Gray4Color", bundle: resourceBundle)

    /// The "Gray5Color" asset catalog color resource.
    nonisolated public static let gray5 = DeveloperToolsSupport.ColorResource(name: "Gray5Color", bundle: resourceBundle)

    /// The "Gray6Color" asset catalog color resource.
    nonisolated public static let gray6 = DeveloperToolsSupport.ColorResource(name: "Gray6Color", bundle: resourceBundle)

    /// The "Gray7Color" asset catalog color resource.
    nonisolated public static let gray7 = DeveloperToolsSupport.ColorResource(name: "Gray7Color", bundle: resourceBundle)

    /// The "Gray8Color" asset catalog color resource.
    nonisolated public static let gray8 = DeveloperToolsSupport.ColorResource(name: "Gray8Color", bundle: resourceBundle)

    /// The "PointColor" asset catalog color resource.
    nonisolated public static let point = DeveloperToolsSupport.ColorResource(name: "PointColor", bundle: resourceBundle)

    /// The "SettingSubTitleColor" asset catalog color resource.
    nonisolated public static let settingSubTitle = DeveloperToolsSupport.ColorResource(name: "SettingSubTitleColor", bundle: resourceBundle)

    /// The "SettingViewTextColor" asset catalog color resource.
    nonisolated public static let settingViewText = DeveloperToolsSupport.ColorResource(name: "SettingViewTextColor", bundle: resourceBundle)

    /// The "TextBlackColor" asset catalog color resource.
    nonisolated public static let textBlack = DeveloperToolsSupport.ColorResource(name: "TextBlackColor", bundle: resourceBundle)

    /// The "TextFieldBackgroundColor" asset catalog color resource.
    nonisolated public static let textFieldBackground = DeveloperToolsSupport.ColorResource(name: "TextFieldBackgroundColor", bundle: resourceBundle)

    /// The "TextGrayColor" asset catalog color resource.
    nonisolated public static let textGray = DeveloperToolsSupport.ColorResource(name: "TextGrayColor", bundle: resourceBundle)

    /// The "TextRedColor" asset catalog color resource.
    nonisolated public static let textRed = DeveloperToolsSupport.ColorResource(name: "TextRedColor", bundle: resourceBundle)

    /// The "ValidNumColor" asset catalog color resource.
    nonisolated public static let validNum = DeveloperToolsSupport.ColorResource(name: "ValidNumColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "AniPickLogo_green" asset catalog image resource.
    nonisolated public static let aniPickLogoGreen = DeveloperToolsSupport.ImageResource(name: "AniPickLogo_green", bundle: resourceBundle)

    /// The "AniPickLogo_purple" asset catalog image resource.
    nonisolated public static let aniPickLogoPurple = DeveloperToolsSupport.ImageResource(name: "AniPickLogo_purple", bundle: resourceBundle)

    /// The "Anipick-logo-green" asset catalog image resource.
    nonisolated public static let anipickLogoGreen = DeveloperToolsSupport.ImageResource(name: "Anipick-logo-green", bundle: resourceBundle)

    /// The "EmptyViewIcon" asset catalog image resource.
    nonisolated public static let emptyViewIcon = DeveloperToolsSupport.ImageResource(name: "EmptyViewIcon", bundle: resourceBundle)

    /// The "GrayToggleOff" asset catalog image resource.
    nonisolated public static let grayToggleOff = DeveloperToolsSupport.ImageResource(name: "GrayToggleOff", bundle: resourceBundle)

    /// The "GrayToggleOn" asset catalog image resource.
    nonisolated public static let grayToggleOn = DeveloperToolsSupport.ImageResource(name: "GrayToggleOn", bundle: resourceBundle)

    /// The "Home_filled" asset catalog image resource.
    nonisolated public static let homeFilled = DeveloperToolsSupport.ImageResource(name: "Home_filled", bundle: resourceBundle)

    /// The "Home_unfilled" asset catalog image resource.
    nonisolated public static let homeUnfilled = DeveloperToolsSupport.ImageResource(name: "Home_unfilled", bundle: resourceBundle)

    /// The "MyInfo_filled" asset catalog image resource.
    nonisolated public static let myInfoFilled = DeveloperToolsSupport.ImageResource(name: "MyInfo_filled", bundle: resourceBundle)

    /// The "MyInfo_unfilled" asset catalog image resource.
    nonisolated public static let myInfoUnfilled = DeveloperToolsSupport.ImageResource(name: "MyInfo_unfilled", bundle: resourceBundle)

    /// The "PinkToggle" asset catalog image resource.
    nonisolated public static let pinkToggle = DeveloperToolsSupport.ImageResource(name: "PinkToggle", bundle: resourceBundle)

    /// The "Ranking_filled" asset catalog image resource.
    nonisolated public static let rankingFilled = DeveloperToolsSupport.ImageResource(name: "Ranking_filled", bundle: resourceBundle)

    /// The "Ranking_unfilled" asset catalog image resource.
    nonisolated public static let rankingUnfilled = DeveloperToolsSupport.ImageResource(name: "Ranking_unfilled", bundle: resourceBundle)

    /// The "RecommendView" asset catalog image resource.
    nonisolated public static let recommendView = DeveloperToolsSupport.ImageResource(name: "RecommendView", bundle: resourceBundle)

    /// The "Reseach_filled" asset catalog image resource.
    nonisolated public static let reseachFilled = DeveloperToolsSupport.ImageResource(name: "Reseach_filled", bundle: resourceBundle)

    /// The "Research_unfilled" asset catalog image resource.
    nonisolated public static let researchUnfilled = DeveloperToolsSupport.ImageResource(name: "Research_unfilled", bundle: resourceBundle)

    /// The "SelectIcon" asset catalog image resource.
    nonisolated public static let selectIcon = DeveloperToolsSupport.ImageResource(name: "SelectIcon", bundle: resourceBundle)

    /// The "SettingIcon" asset catalog image resource.
    nonisolated public static let settingIcon = DeveloperToolsSupport.ImageResource(name: "SettingIcon", bundle: resourceBundle)

    /// The "ToggleDisable" asset catalog image resource.
    nonisolated public static let toggleDisable = DeveloperToolsSupport.ImageResource(name: "ToggleDisable", bundle: resourceBundle)

    /// The "ToggleEnable" asset catalog image resource.
    nonisolated public static let toggleEnable = DeveloperToolsSupport.ImageResource(name: "ToggleEnable", bundle: resourceBundle)

    /// The "UpTrianglePink" asset catalog image resource.
    nonisolated public static let upTrianglePink = DeveloperToolsSupport.ImageResource(name: "UpTrianglePink", bundle: resourceBundle)

    /// The "alert-circle" asset catalog image resource.
    nonisolated public static let alertCircle = DeveloperToolsSupport.ImageResource(name: "alert-circle", bundle: resourceBundle)

    /// The "all_clear_button" asset catalog image resource.
    nonisolated public static let allClearButton = DeveloperToolsSupport.ImageResource(name: "all_clear_button", bundle: resourceBundle)

    /// The "animeThumbnail" asset catalog image resource.
    nonisolated public static let animeThumbnail = DeveloperToolsSupport.ImageResource(name: "animeThumbnail", bundle: resourceBundle)

    /// The "animeThumbnailOnlyAdult" asset catalog image resource.
    nonisolated public static let animeThumbnailOnlyAdult = DeveloperToolsSupport.ImageResource(name: "animeThumbnailOnlyAdult", bundle: resourceBundle)

    /// The "appleLoginButton" asset catalog image resource.
    nonisolated public static let appleLoginButton = DeveloperToolsSupport.ImageResource(name: "appleLoginButton", bundle: resourceBundle)

    /// The "check" asset catalog image resource.
    nonisolated public static let check = DeveloperToolsSupport.ImageResource(name: "check", bundle: resourceBundle)

    /// The "chevron-down-blue" asset catalog image resource.
    nonisolated public static let chevronDownBlue = DeveloperToolsSupport.ImageResource(name: "chevron-down-blue", bundle: resourceBundle)

    /// The "chevron-down-gray" asset catalog image resource.
    nonisolated public static let chevronDownGray = DeveloperToolsSupport.ImageResource(name: "chevron-down-gray", bundle: resourceBundle)

    /// The "chevron-down-primaryColor" asset catalog image resource.
    nonisolated public static let chevronDownPrimary = DeveloperToolsSupport.ImageResource(name: "chevron-down-primaryColor", bundle: resourceBundle)

    /// The "chevron-left" asset catalog image resource.
    nonisolated public static let chevronLeft = DeveloperToolsSupport.ImageResource(name: "chevron-left", bundle: resourceBundle)

    /// The "chevron-left-gray" asset catalog image resource.
    nonisolated public static let chevronLeftGray = DeveloperToolsSupport.ImageResource(name: "chevron-left-gray", bundle: resourceBundle)

    /// The "chevron-left-stroke" asset catalog image resource.
    nonisolated public static let chevronLeftStroke = DeveloperToolsSupport.ImageResource(name: "chevron-left-stroke", bundle: resourceBundle)

    /// The "chevron-right" asset catalog image resource.
    nonisolated public static let chevronRight = DeveloperToolsSupport.ImageResource(name: "chevron-right", bundle: resourceBundle)

    /// The "chevron-up" asset catalog image resource.
    nonisolated public static let chevronUp = DeveloperToolsSupport.ImageResource(name: "chevron-up", bundle: resourceBundle)

    /// The "chevron-up-blue" asset catalog image resource.
    nonisolated public static let chevronUpBlue = DeveloperToolsSupport.ImageResource(name: "chevron-up-blue", bundle: resourceBundle)

    /// The "chevrons-down" asset catalog image resource.
    nonisolated public static let chevronsDown = DeveloperToolsSupport.ImageResource(name: "chevrons-down", bundle: resourceBundle)

    /// The "chevrons-left" asset catalog image resource.
    nonisolated public static let chevronsLeft = DeveloperToolsSupport.ImageResource(name: "chevrons-left", bundle: resourceBundle)

    /// The "chevrons-right" asset catalog image resource.
    nonisolated public static let chevronsRight = DeveloperToolsSupport.ImageResource(name: "chevrons-right", bundle: resourceBundle)

    /// The "chevrons-up" asset catalog image resource.
    nonisolated public static let chevronsUp = DeveloperToolsSupport.ImageResource(name: "chevrons-up", bundle: resourceBundle)

    /// The "cloud-image" asset catalog image resource.
    nonisolated public static let cloud = DeveloperToolsSupport.ImageResource(name: "cloud-image", bundle: resourceBundle)

    /// The "downTriangleBlue" asset catalog image resource.
    nonisolated public static let downTriangleBlue = DeveloperToolsSupport.ImageResource(name: "downTriangleBlue", bundle: resourceBundle)

    /// The "edit-3" asset catalog image resource.
    nonisolated public static let edit3 = DeveloperToolsSupport.ImageResource(name: "edit-3", bundle: resourceBundle)

    /// The "edit-profile-button" asset catalog image resource.
    nonisolated public static let editProfileButton = DeveloperToolsSupport.ImageResource(name: "edit-profile-button", bundle: resourceBundle)

    /// The "emptyLikeAnime" asset catalog image resource.
    nonisolated public static let emptyLikeAnime = DeveloperToolsSupport.ImageResource(name: "emptyLikeAnime", bundle: resourceBundle)

    /// The "emptyLikePerson" asset catalog image resource.
    nonisolated public static let emptyLikePerson = DeveloperToolsSupport.ImageResource(name: "emptyLikePerson", bundle: resourceBundle)

    /// The "empty_background_img" asset catalog image resource.
    nonisolated public static let emptyBackgroundImg = DeveloperToolsSupport.ImageResource(name: "empty_background_img", bundle: resourceBundle)

    /// The "empty_finished_icon" asset catalog image resource.
    nonisolated public static let emptyFinishedIcon = DeveloperToolsSupport.ImageResource(name: "empty_finished_icon", bundle: resourceBundle)

    /// The "empty_recent_viewed" asset catalog image resource.
    nonisolated public static let emptyRecentViewed = DeveloperToolsSupport.ImageResource(name: "empty_recent_viewed", bundle: resourceBundle)

    /// The "empty_recommendation" asset catalog image resource.
    nonisolated public static let emptyRecommendation = DeveloperToolsSupport.ImageResource(name: "empty_recommendation", bundle: resourceBundle)

    /// The "empty_review_icon" asset catalog image resource.
    nonisolated public static let emptyReviewIcon = DeveloperToolsSupport.ImageResource(name: "empty_review_icon", bundle: resourceBundle)

    /// The "empty_to_watch_list_icon" asset catalog image resource.
    nonisolated public static let emptyToWatchListIcon = DeveloperToolsSupport.ImageResource(name: "empty_to_watch_list_icon", bundle: resourceBundle)

    /// The "eyeVisibleIcons" asset catalog image resource.
    nonisolated public static let eyeVisibleIcons = DeveloperToolsSupport.ImageResource(name: "eyeVisibleIcons", bundle: resourceBundle)

    /// The "eye_unvisible_Icons" asset catalog image resource.
    nonisolated public static let eyeUnvisibleIcons = DeveloperToolsSupport.ImageResource(name: "eye_unvisible_Icons", bundle: resourceBundle)

    /// The "fill-heart-green" asset catalog image resource.
    nonisolated public static let fillHeartGreen = DeveloperToolsSupport.ImageResource(name: "fill-heart-green", bundle: resourceBundle)

    /// The "fill-pick-star" asset catalog image resource.
    nonisolated public static let fillPickStar = DeveloperToolsSupport.ImageResource(name: "fill-pick-star", bundle: resourceBundle)

    /// The "filled-heart-pink" asset catalog image resource.
    nonisolated public static let filledHeartPink = DeveloperToolsSupport.ImageResource(name: "filled-heart-pink", bundle: resourceBundle)

    /// The "googleLoginButton" asset catalog image resource.
    nonisolated public static let googleLoginButton = DeveloperToolsSupport.ImageResource(name: "googleLoginButton", bundle: resourceBundle)

    /// The "half-star" asset catalog image resource.
    nonisolated public static let halfStar = DeveloperToolsSupport.ImageResource(name: "half-star", bundle: resourceBundle)

    /// The "heart" asset catalog image resource.
    nonisolated public static let heart = DeveloperToolsSupport.ImageResource(name: "heart", bundle: resourceBundle)

    /// The "image" asset catalog image resource.
    nonisolated public static let image = DeveloperToolsSupport.ImageResource(name: "image", bundle: resourceBundle)

    /// The "instagramIcon" asset catalog image resource.
    nonisolated public static let instagramIcon = DeveloperToolsSupport.ImageResource(name: "instagramIcon", bundle: resourceBundle)

    /// The "instagramIconSmall" asset catalog image resource.
    nonisolated public static let instagramIconSmall = DeveloperToolsSupport.ImageResource(name: "instagramIconSmall", bundle: resourceBundle)

    /// The "kakaoLoginButton" asset catalog image resource.
    nonisolated public static let kakaoLoginButton = DeveloperToolsSupport.ImageResource(name: "kakaoLoginButton", bundle: resourceBundle)

    /// The "more-horizontal" asset catalog image resource.
    nonisolated public static let moreHorizontal = DeveloperToolsSupport.ImageResource(name: "more-horizontal", bundle: resourceBundle)

    /// The "more-vertical" asset catalog image resource.
    nonisolated public static let moreVertical = DeveloperToolsSupport.ImageResource(name: "more-vertical", bundle: resourceBundle)

    /// The "more-vertical-gray" asset catalog image resource.
    nonisolated public static let moreVerticalGray = DeveloperToolsSupport.ImageResource(name: "more-vertical-gray", bundle: resourceBundle)

    /// The "recentKeywordClearX" asset catalog image resource.
    nonisolated public static let recentKeywordClearX = DeveloperToolsSupport.ImageResource(name: "recentKeywordClearX", bundle: resourceBundle)

    /// The "searchIcons-darkgray" asset catalog image resource.
    nonisolated public static let searchIconsDarkgray = DeveloperToolsSupport.ImageResource(name: "searchIcons-darkgray", bundle: resourceBundle)

    /// The "searchIcons-gray" asset catalog image resource.
    nonisolated public static let searchIconsGray = DeveloperToolsSupport.ImageResource(name: "searchIcons-gray", bundle: resourceBundle)

    /// The "share" asset catalog image resource.
    nonisolated public static let share = DeveloperToolsSupport.ImageResource(name: "share", bundle: resourceBundle)

    /// The "shareButton" asset catalog image resource.
    nonisolated public static let shareButton = DeveloperToolsSupport.ImageResource(name: "shareButton", bundle: resourceBundle)

    /// The "unSelectIcon" asset catalog image resource.
    nonisolated public static let unSelectIcon = DeveloperToolsSupport.ImageResource(name: "unSelectIcon", bundle: resourceBundle)

    /// The "uncheck" asset catalog image resource.
    nonisolated public static let uncheck = DeveloperToolsSupport.ImageResource(name: "uncheck", bundle: resourceBundle)

    /// The "unfill-star" asset catalog image resource.
    nonisolated public static let unfillStar = DeveloperToolsSupport.ImageResource(name: "unfill-star", bundle: resourceBundle)

    /// The "unfilled-heart" asset catalog image resource.
    nonisolated public static let unfilledHeart = DeveloperToolsSupport.ImageResource(name: "unfilled-heart", bundle: resourceBundle)

    /// The "x_button" asset catalog image resource.
    nonisolated public static let xButton = DeveloperToolsSupport.ImageResource(name: "x_button", bundle: resourceBundle)

    /// The "x_button_green" asset catalog image resource.
    nonisolated public static let xButtonGreen = DeveloperToolsSupport.ImageResource(name: "x_button_green", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AnipickBlackColor" asset catalog color.
    nonisolated public static var anipickBlack: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .anipickBlack)
#else
        return .init()
#endif
    }

    /// The "AnipickPrimaryColor" asset catalog color.
    nonisolated public static var anipickPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .anipickPrimary)
#else
        return .init()
#endif
    }

    /// The "AnipickSecondaryColor" asset catalog color.
    nonisolated public static var anipickSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .anipickSecondary)
#else
        return .init()
#endif
    }

    /// The "BackgroundColor" asset catalog color.
    nonisolated public static var background: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .background)
#else
        return .init()
#endif
    }

    /// The "Gray4Color" asset catalog color.
    nonisolated public static var gray4: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .gray4)
#else
        return .init()
#endif
    }

    /// The "Gray5Color" asset catalog color.
    nonisolated public static var gray5: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .gray5)
#else
        return .init()
#endif
    }

    /// The "Gray6Color" asset catalog color.
    nonisolated public static var gray6: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .gray6)
#else
        return .init()
#endif
    }

    /// The "Gray7Color" asset catalog color.
    nonisolated public static var gray7: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .gray7)
#else
        return .init()
#endif
    }

    /// The "Gray8Color" asset catalog color.
    nonisolated public static var gray8: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .gray8)
#else
        return .init()
#endif
    }

    /// The "PointColor" asset catalog color.
    nonisolated public static var point: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .point)
#else
        return .init()
#endif
    }

    /// The "SettingSubTitleColor" asset catalog color.
    nonisolated public static var settingSubTitle: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .settingSubTitle)
#else
        return .init()
#endif
    }

    /// The "SettingViewTextColor" asset catalog color.
    nonisolated public static var settingViewText: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .settingViewText)
#else
        return .init()
#endif
    }

    /// The "TextBlackColor" asset catalog color.
    nonisolated public static var textBlack: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .textBlack)
#else
        return .init()
#endif
    }

    /// The "TextFieldBackgroundColor" asset catalog color.
    nonisolated public static var textFieldBackground: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .textFieldBackground)
#else
        return .init()
#endif
    }

    /// The "TextGrayColor" asset catalog color.
    nonisolated public static var textGray: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .textGray)
#else
        return .init()
#endif
    }

    /// The "TextRedColor" asset catalog color.
    nonisolated public static var textRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .textRed)
#else
        return .init()
#endif
    }

    /// The "ValidNumColor" asset catalog color.
    nonisolated public static var validNum: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .validNum)
#else
        return .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AnipickBlackColor" asset catalog color.
    nonisolated public static var anipickBlack: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .anipickBlack)
#else
        return .init()
#endif
    }

    /// The "AnipickPrimaryColor" asset catalog color.
    nonisolated public static var anipickPrimary: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .anipickPrimary)
#else
        return .init()
#endif
    }

    /// The "AnipickSecondaryColor" asset catalog color.
    nonisolated public static var anipickSecondary: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .anipickSecondary)
#else
        return .init()
#endif
    }

    /// The "BackgroundColor" asset catalog color.
    nonisolated public static var background: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .background)
#else
        return .init()
#endif
    }

    /// The "Gray4Color" asset catalog color.
    nonisolated public static var gray4: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .gray4)
#else
        return .init()
#endif
    }

    /// The "Gray5Color" asset catalog color.
    nonisolated public static var gray5: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .gray5)
#else
        return .init()
#endif
    }

    /// The "Gray6Color" asset catalog color.
    nonisolated public static var gray6: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .gray6)
#else
        return .init()
#endif
    }

    /// The "Gray7Color" asset catalog color.
    nonisolated public static var gray7: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .gray7)
#else
        return .init()
#endif
    }

    /// The "Gray8Color" asset catalog color.
    nonisolated public static var gray8: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .gray8)
#else
        return .init()
#endif
    }

    /// The "PointColor" asset catalog color.
    nonisolated public static var point: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .point)
#else
        return .init()
#endif
    }

    /// The "SettingSubTitleColor" asset catalog color.
    nonisolated public static var settingSubTitle: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .settingSubTitle)
#else
        return .init()
#endif
    }

    /// The "SettingViewTextColor" asset catalog color.
    nonisolated public static var settingViewText: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .settingViewText)
#else
        return .init()
#endif
    }

    /// The "TextBlackColor" asset catalog color.
    nonisolated public static var textBlack: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .textBlack)
#else
        return .init()
#endif
    }

    /// The "TextFieldBackgroundColor" asset catalog color.
    nonisolated public static var textFieldBackground: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .textFieldBackground)
#else
        return .init()
#endif
    }

    /// The "TextGrayColor" asset catalog color.
    nonisolated public static var textGray: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .textGray)
#else
        return .init()
#endif
    }

    /// The "TextRedColor" asset catalog color.
    nonisolated public static var textRed: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .textRed)
#else
        return .init()
#endif
    }

    /// The "ValidNumColor" asset catalog color.
    nonisolated public static var validNum: UIKit.UIColor {
#if !os(watchOS)
        return .init(resource: .validNum)
#else
        return .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AnipickBlackColor" asset catalog color.
    nonisolated public static var anipickBlack: SwiftUI.Color { return .init(.anipickBlack) }

    /// The "AnipickPrimaryColor" asset catalog color.
    nonisolated public static var anipickPrimary: SwiftUI.Color { return .init(.anipickPrimary) }

    /// The "AnipickSecondaryColor" asset catalog color.
    nonisolated public static var anipickSecondary: SwiftUI.Color { return .init(.anipickSecondary) }

    /// The "BackgroundColor" asset catalog color.
    nonisolated public static var background: SwiftUI.Color { return .init(.background) }

    /// The "Gray4Color" asset catalog color.
    nonisolated public static var gray4: SwiftUI.Color { return .init(.gray4) }

    /// The "Gray5Color" asset catalog color.
    nonisolated public static var gray5: SwiftUI.Color { return .init(.gray5) }

    /// The "Gray6Color" asset catalog color.
    nonisolated public static var gray6: SwiftUI.Color { return .init(.gray6) }

    /// The "Gray7Color" asset catalog color.
    nonisolated public static var gray7: SwiftUI.Color { return .init(.gray7) }

    /// The "Gray8Color" asset catalog color.
    nonisolated public static var gray8: SwiftUI.Color { return .init(.gray8) }

    /// The "PointColor" asset catalog color.
    nonisolated public static var point: SwiftUI.Color { return .init(.point) }

    /// The "SettingSubTitleColor" asset catalog color.
    nonisolated public static var settingSubTitle: SwiftUI.Color { return .init(.settingSubTitle) }

    /// The "SettingViewTextColor" asset catalog color.
    nonisolated public static var settingViewText: SwiftUI.Color { return .init(.settingViewText) }

    /// The "TextBlackColor" asset catalog color.
    nonisolated public static var textBlack: SwiftUI.Color { return .init(.textBlack) }

    /// The "TextFieldBackgroundColor" asset catalog color.
    nonisolated public static var textFieldBackground: SwiftUI.Color { return .init(.textFieldBackground) }

    /// The "TextGrayColor" asset catalog color.
    nonisolated public static var textGray: SwiftUI.Color { return .init(.textGray) }

    /// The "TextRedColor" asset catalog color.
    nonisolated public static var textRed: SwiftUI.Color { return .init(.textRed) }

    /// The "ValidNumColor" asset catalog color.
    nonisolated public static var validNum: SwiftUI.Color { return .init(.validNum) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AnipickBlackColor" asset catalog color.
    nonisolated public static var anipickBlack: SwiftUI.Color { return .init(.anipickBlack) }

    /// The "AnipickPrimaryColor" asset catalog color.
    nonisolated public static var anipickPrimary: SwiftUI.Color { return .init(.anipickPrimary) }

    /// The "AnipickSecondaryColor" asset catalog color.
    nonisolated public static var anipickSecondary: SwiftUI.Color { return .init(.anipickSecondary) }

    /// The "BackgroundColor" asset catalog color.
    nonisolated public static var background: SwiftUI.Color { return .init(.background) }

    /// The "Gray4Color" asset catalog color.
    nonisolated public static var gray4: SwiftUI.Color { return .init(.gray4) }

    /// The "Gray5Color" asset catalog color.
    nonisolated public static var gray5: SwiftUI.Color { return .init(.gray5) }

    /// The "Gray6Color" asset catalog color.
    nonisolated public static var gray6: SwiftUI.Color { return .init(.gray6) }

    /// The "Gray7Color" asset catalog color.
    nonisolated public static var gray7: SwiftUI.Color { return .init(.gray7) }

    /// The "Gray8Color" asset catalog color.
    nonisolated public static var gray8: SwiftUI.Color { return .init(.gray8) }

    /// The "PointColor" asset catalog color.
    nonisolated public static var point: SwiftUI.Color { return .init(.point) }

    /// The "SettingSubTitleColor" asset catalog color.
    nonisolated public static var settingSubTitle: SwiftUI.Color { return .init(.settingSubTitle) }

    /// The "SettingViewTextColor" asset catalog color.
    nonisolated public static var settingViewText: SwiftUI.Color { return .init(.settingViewText) }

    /// The "TextBlackColor" asset catalog color.
    nonisolated public static var textBlack: SwiftUI.Color { return .init(.textBlack) }

    /// The "TextFieldBackgroundColor" asset catalog color.
    nonisolated public static var textFieldBackground: SwiftUI.Color { return .init(.textFieldBackground) }

    /// The "TextGrayColor" asset catalog color.
    nonisolated public static var textGray: SwiftUI.Color { return .init(.textGray) }

    /// The "TextRedColor" asset catalog color.
    nonisolated public static var textRed: SwiftUI.Color { return .init(.textRed) }

    /// The "ValidNumColor" asset catalog color.
    nonisolated public static var validNum: SwiftUI.Color { return .init(.validNum) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "AniPickLogo_green" asset catalog image.
    nonisolated public static var aniPickLogoGreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .aniPickLogoGreen)
#else
        return .init()
#endif
    }

    /// The "AniPickLogo_purple" asset catalog image.
    nonisolated public static var aniPickLogoPurple: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .aniPickLogoPurple)
#else
        return .init()
#endif
    }

    /// The "Anipick-logo-green" asset catalog image.
    nonisolated public static var anipickLogoGreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .anipickLogoGreen)
#else
        return .init()
#endif
    }

    /// The "EmptyViewIcon" asset catalog image.
    nonisolated public static var emptyViewIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyViewIcon)
#else
        return .init()
#endif
    }

    /// The "GrayToggleOff" asset catalog image.
    nonisolated public static var grayToggleOff: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .grayToggleOff)
#else
        return .init()
#endif
    }

    /// The "GrayToggleOn" asset catalog image.
    nonisolated public static var grayToggleOn: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .grayToggleOn)
#else
        return .init()
#endif
    }

    /// The "Home_filled" asset catalog image.
    nonisolated public static var homeFilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .homeFilled)
#else
        return .init()
#endif
    }

    /// The "Home_unfilled" asset catalog image.
    nonisolated public static var homeUnfilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .homeUnfilled)
#else
        return .init()
#endif
    }

    /// The "MyInfo_filled" asset catalog image.
    nonisolated public static var myInfoFilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .myInfoFilled)
#else
        return .init()
#endif
    }

    /// The "MyInfo_unfilled" asset catalog image.
    nonisolated public static var myInfoUnfilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .myInfoUnfilled)
#else
        return .init()
#endif
    }

    /// The "PinkToggle" asset catalog image.
    nonisolated public static var pinkToggle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .pinkToggle)
#else
        return .init()
#endif
    }

    /// The "Ranking_filled" asset catalog image.
    nonisolated public static var rankingFilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .rankingFilled)
#else
        return .init()
#endif
    }

    /// The "Ranking_unfilled" asset catalog image.
    nonisolated public static var rankingUnfilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .rankingUnfilled)
#else
        return .init()
#endif
    }

    /// The "RecommendView" asset catalog image.
    nonisolated public static var recommendView: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .recommendView)
#else
        return .init()
#endif
    }

    /// The "Reseach_filled" asset catalog image.
    nonisolated public static var reseachFilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .reseachFilled)
#else
        return .init()
#endif
    }

    /// The "Research_unfilled" asset catalog image.
    nonisolated public static var researchUnfilled: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .researchUnfilled)
#else
        return .init()
#endif
    }

    /// The "SelectIcon" asset catalog image.
    nonisolated public static var selectIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .selectIcon)
#else
        return .init()
#endif
    }

    /// The "SettingIcon" asset catalog image.
    nonisolated public static var settingIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .settingIcon)
#else
        return .init()
#endif
    }

    /// The "ToggleDisable" asset catalog image.
    nonisolated public static var toggleDisable: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .toggleDisable)
#else
        return .init()
#endif
    }

    /// The "ToggleEnable" asset catalog image.
    nonisolated public static var toggleEnable: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .toggleEnable)
#else
        return .init()
#endif
    }

    /// The "UpTrianglePink" asset catalog image.
    nonisolated public static var upTrianglePink: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .upTrianglePink)
#else
        return .init()
#endif
    }

    /// The "alert-circle" asset catalog image.
    nonisolated public static var alertCircle: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .alertCircle)
#else
        return .init()
#endif
    }

    /// The "all_clear_button" asset catalog image.
    nonisolated public static var allClearButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .allClearButton)
#else
        return .init()
#endif
    }

    /// The "animeThumbnail" asset catalog image.
    nonisolated public static var animeThumbnail: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .animeThumbnail)
#else
        return .init()
#endif
    }

    /// The "animeThumbnailOnlyAdult" asset catalog image.
    nonisolated public static var animeThumbnailOnlyAdult: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .animeThumbnailOnlyAdult)
#else
        return .init()
#endif
    }

    /// The "appleLoginButton" asset catalog image.
    nonisolated public static var appleLoginButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .appleLoginButton)
#else
        return .init()
#endif
    }

    /// The "check" asset catalog image.
    nonisolated public static var check: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .check)
#else
        return .init()
#endif
    }

    /// The "chevron-down-blue" asset catalog image.
    nonisolated public static var chevronDownBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronDownBlue)
#else
        return .init()
#endif
    }

    /// The "chevron-down-gray" asset catalog image.
    nonisolated public static var chevronDownGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronDownGray)
#else
        return .init()
#endif
    }

    /// The "chevron-down-primaryColor" asset catalog image.
    nonisolated public static var chevronDownPrimary: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronDownPrimary)
#else
        return .init()
#endif
    }

    /// The "chevron-left" asset catalog image.
    nonisolated public static var chevronLeft: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronLeft)
#else
        return .init()
#endif
    }

    /// The "chevron-left-gray" asset catalog image.
    nonisolated public static var chevronLeftGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronLeftGray)
#else
        return .init()
#endif
    }

    /// The "chevron-left-stroke" asset catalog image.
    nonisolated public static var chevronLeftStroke: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronLeftStroke)
#else
        return .init()
#endif
    }

    /// The "chevron-right" asset catalog image.
    nonisolated public static var chevronRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronRight)
#else
        return .init()
#endif
    }

    /// The "chevron-up" asset catalog image.
    nonisolated public static var chevronUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronUp)
#else
        return .init()
#endif
    }

    /// The "chevron-up-blue" asset catalog image.
    nonisolated public static var chevronUpBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronUpBlue)
#else
        return .init()
#endif
    }

    /// The "chevrons-down" asset catalog image.
    nonisolated public static var chevronsDown: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronsDown)
#else
        return .init()
#endif
    }

    /// The "chevrons-left" asset catalog image.
    nonisolated public static var chevronsLeft: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronsLeft)
#else
        return .init()
#endif
    }

    /// The "chevrons-right" asset catalog image.
    nonisolated public static var chevronsRight: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronsRight)
#else
        return .init()
#endif
    }

    /// The "chevrons-up" asset catalog image.
    nonisolated public static var chevronsUp: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .chevronsUp)
#else
        return .init()
#endif
    }

    /// The "cloud-image" asset catalog image.
    nonisolated public static var cloud: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .cloud)
#else
        return .init()
#endif
    }

    /// The "downTriangleBlue" asset catalog image.
    nonisolated public static var downTriangleBlue: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .downTriangleBlue)
#else
        return .init()
#endif
    }

    /// The "edit-3" asset catalog image.
    nonisolated public static var edit3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .edit3)
#else
        return .init()
#endif
    }

    /// The "edit-profile-button" asset catalog image.
    nonisolated public static var editProfileButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .editProfileButton)
#else
        return .init()
#endif
    }

    /// The "emptyLikeAnime" asset catalog image.
    nonisolated public static var emptyLikeAnime: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyLikeAnime)
#else
        return .init()
#endif
    }

    /// The "emptyLikePerson" asset catalog image.
    nonisolated public static var emptyLikePerson: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyLikePerson)
#else
        return .init()
#endif
    }

    /// The "empty_background_img" asset catalog image.
    nonisolated public static var emptyBackgroundImg: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyBackgroundImg)
#else
        return .init()
#endif
    }

    /// The "empty_finished_icon" asset catalog image.
    nonisolated public static var emptyFinishedIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyFinishedIcon)
#else
        return .init()
#endif
    }

    /// The "empty_recent_viewed" asset catalog image.
    nonisolated public static var emptyRecentViewed: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyRecentViewed)
#else
        return .init()
#endif
    }

    /// The "empty_recommendation" asset catalog image.
    nonisolated public static var emptyRecommendation: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyRecommendation)
#else
        return .init()
#endif
    }

    /// The "empty_review_icon" asset catalog image.
    nonisolated public static var emptyReviewIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyReviewIcon)
#else
        return .init()
#endif
    }

    /// The "empty_to_watch_list_icon" asset catalog image.
    nonisolated public static var emptyToWatchListIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .emptyToWatchListIcon)
#else
        return .init()
#endif
    }

    /// The "eyeVisibleIcons" asset catalog image.
    nonisolated public static var eyeVisibleIcons: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .eyeVisibleIcons)
#else
        return .init()
#endif
    }

    /// The "eye_unvisible_Icons" asset catalog image.
    nonisolated public static var eyeUnvisibleIcons: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .eyeUnvisibleIcons)
#else
        return .init()
#endif
    }

    /// The "fill-heart-green" asset catalog image.
    nonisolated public static var fillHeartGreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .fillHeartGreen)
#else
        return .init()
#endif
    }

    /// The "fill-pick-star" asset catalog image.
    nonisolated public static var fillPickStar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .fillPickStar)
#else
        return .init()
#endif
    }

    /// The "filled-heart-pink" asset catalog image.
    nonisolated public static var filledHeartPink: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .filledHeartPink)
#else
        return .init()
#endif
    }

    /// The "googleLoginButton" asset catalog image.
    nonisolated public static var googleLoginButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .googleLoginButton)
#else
        return .init()
#endif
    }

    /// The "half-star" asset catalog image.
    nonisolated public static var halfStar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .halfStar)
#else
        return .init()
#endif
    }

    /// The "heart" asset catalog image.
    nonisolated public static var heart: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .heart)
#else
        return .init()
#endif
    }

    /// The "image" asset catalog image.
    nonisolated public static var image: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .image)
#else
        return .init()
#endif
    }

    /// The "instagramIcon" asset catalog image.
    nonisolated public static var instagramIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .instagramIcon)
#else
        return .init()
#endif
    }

    /// The "instagramIconSmall" asset catalog image.
    nonisolated public static var instagramIconSmall: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .instagramIconSmall)
#else
        return .init()
#endif
    }

    /// The "kakaoLoginButton" asset catalog image.
    nonisolated public static var kakaoLoginButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .kakaoLoginButton)
#else
        return .init()
#endif
    }

    /// The "more-horizontal" asset catalog image.
    nonisolated public static var moreHorizontal: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .moreHorizontal)
#else
        return .init()
#endif
    }

    /// The "more-vertical" asset catalog image.
    nonisolated public static var moreVertical: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .moreVertical)
#else
        return .init()
#endif
    }

    /// The "more-vertical-gray" asset catalog image.
    nonisolated public static var moreVerticalGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .moreVerticalGray)
#else
        return .init()
#endif
    }

    /// The "recentKeywordClearX" asset catalog image.
    nonisolated public static var recentKeywordClearX: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .recentKeywordClearX)
#else
        return .init()
#endif
    }

    /// The "searchIcons-darkgray" asset catalog image.
    nonisolated public static var searchIconsDarkgray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .searchIconsDarkgray)
#else
        return .init()
#endif
    }

    /// The "searchIcons-gray" asset catalog image.
    nonisolated public static var searchIconsGray: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .searchIconsGray)
#else
        return .init()
#endif
    }

    /// The "share" asset catalog image.
    nonisolated public static var share: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .share)
#else
        return .init()
#endif
    }

    /// The "shareButton" asset catalog image.
    nonisolated public static var shareButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .shareButton)
#else
        return .init()
#endif
    }

    /// The "unSelectIcon" asset catalog image.
    nonisolated public static var unSelectIcon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .unSelectIcon)
#else
        return .init()
#endif
    }

    /// The "uncheck" asset catalog image.
    nonisolated public static var uncheck: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .uncheck)
#else
        return .init()
#endif
    }

    /// The "unfill-star" asset catalog image.
    nonisolated public static var unfillStar: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .unfillStar)
#else
        return .init()
#endif
    }

    /// The "unfilled-heart" asset catalog image.
    nonisolated public static var unfilledHeart: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .unfilledHeart)
#else
        return .init()
#endif
    }

    /// The "x_button" asset catalog image.
    nonisolated public static var xButton: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .xButton)
#else
        return .init()
#endif
    }

    /// The "x_button_green" asset catalog image.
    nonisolated public static var xButtonGreen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        return .init(resource: .xButtonGreen)
#else
        return .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "AniPickLogo_green" asset catalog image.
    nonisolated public static var aniPickLogoGreen: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .aniPickLogoGreen)
#else
        return .init()
#endif
    }

    /// The "AniPickLogo_purple" asset catalog image.
    nonisolated public static var aniPickLogoPurple: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .aniPickLogoPurple)
#else
        return .init()
#endif
    }

    /// The "Anipick-logo-green" asset catalog image.
    nonisolated public static var anipickLogoGreen: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .anipickLogoGreen)
#else
        return .init()
#endif
    }

    /// The "EmptyViewIcon" asset catalog image.
    nonisolated public static var emptyViewIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyViewIcon)
#else
        return .init()
#endif
    }

    /// The "GrayToggleOff" asset catalog image.
    nonisolated public static var grayToggleOff: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .grayToggleOff)
#else
        return .init()
#endif
    }

    /// The "GrayToggleOn" asset catalog image.
    nonisolated public static var grayToggleOn: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .grayToggleOn)
#else
        return .init()
#endif
    }

    /// The "Home_filled" asset catalog image.
    nonisolated public static var homeFilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .homeFilled)
#else
        return .init()
#endif
    }

    /// The "Home_unfilled" asset catalog image.
    nonisolated public static var homeUnfilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .homeUnfilled)
#else
        return .init()
#endif
    }

    /// The "MyInfo_filled" asset catalog image.
    nonisolated public static var myInfoFilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .myInfoFilled)
#else
        return .init()
#endif
    }

    /// The "MyInfo_unfilled" asset catalog image.
    nonisolated public static var myInfoUnfilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .myInfoUnfilled)
#else
        return .init()
#endif
    }

    /// The "PinkToggle" asset catalog image.
    nonisolated public static var pinkToggle: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .pinkToggle)
#else
        return .init()
#endif
    }

    /// The "Ranking_filled" asset catalog image.
    nonisolated public static var rankingFilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .rankingFilled)
#else
        return .init()
#endif
    }

    /// The "Ranking_unfilled" asset catalog image.
    nonisolated public static var rankingUnfilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .rankingUnfilled)
#else
        return .init()
#endif
    }

    /// The "RecommendView" asset catalog image.
    nonisolated public static var recommendView: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .recommendView)
#else
        return .init()
#endif
    }

    /// The "Reseach_filled" asset catalog image.
    nonisolated public static var reseachFilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .reseachFilled)
#else
        return .init()
#endif
    }

    /// The "Research_unfilled" asset catalog image.
    nonisolated public static var researchUnfilled: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .researchUnfilled)
#else
        return .init()
#endif
    }

    /// The "SelectIcon" asset catalog image.
    nonisolated public static var selectIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .selectIcon)
#else
        return .init()
#endif
    }

    /// The "SettingIcon" asset catalog image.
    nonisolated public static var settingIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .settingIcon)
#else
        return .init()
#endif
    }

    /// The "ToggleDisable" asset catalog image.
    nonisolated public static var toggleDisable: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .toggleDisable)
#else
        return .init()
#endif
    }

    /// The "ToggleEnable" asset catalog image.
    nonisolated public static var toggleEnable: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .toggleEnable)
#else
        return .init()
#endif
    }

    /// The "UpTrianglePink" asset catalog image.
    nonisolated public static var upTrianglePink: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .upTrianglePink)
#else
        return .init()
#endif
    }

    /// The "alert-circle" asset catalog image.
    nonisolated public static var alertCircle: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .alertCircle)
#else
        return .init()
#endif
    }

    /// The "all_clear_button" asset catalog image.
    nonisolated public static var allClearButton: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .allClearButton)
#else
        return .init()
#endif
    }

    /// The "animeThumbnail" asset catalog image.
    nonisolated public static var animeThumbnail: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .animeThumbnail)
#else
        return .init()
#endif
    }

    /// The "animeThumbnailOnlyAdult" asset catalog image.
    nonisolated public static var animeThumbnailOnlyAdult: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .animeThumbnailOnlyAdult)
#else
        return .init()
#endif
    }

    /// The "appleLoginButton" asset catalog image.
    nonisolated public static var appleLoginButton: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .appleLoginButton)
#else
        return .init()
#endif
    }

    /// The "check" asset catalog image.
    nonisolated public static var check: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .check)
#else
        return .init()
#endif
    }

    /// The "chevron-down-blue" asset catalog image.
    nonisolated public static var chevronDownBlue: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronDownBlue)
#else
        return .init()
#endif
    }

    /// The "chevron-down-gray" asset catalog image.
    nonisolated public static var chevronDownGray: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronDownGray)
#else
        return .init()
#endif
    }

    /// The "chevron-down-primaryColor" asset catalog image.
    nonisolated public static var chevronDownPrimary: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronDownPrimary)
#else
        return .init()
#endif
    }

    /// The "chevron-left" asset catalog image.
    nonisolated public static var chevronLeft: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronLeft)
#else
        return .init()
#endif
    }

    /// The "chevron-left-gray" asset catalog image.
    nonisolated public static var chevronLeftGray: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronLeftGray)
#else
        return .init()
#endif
    }

    /// The "chevron-left-stroke" asset catalog image.
    nonisolated public static var chevronLeftStroke: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronLeftStroke)
#else
        return .init()
#endif
    }

    /// The "chevron-right" asset catalog image.
    nonisolated public static var chevronRight: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronRight)
#else
        return .init()
#endif
    }

    /// The "chevron-up" asset catalog image.
    nonisolated public static var chevronUp: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronUp)
#else
        return .init()
#endif
    }

    /// The "chevron-up-blue" asset catalog image.
    nonisolated public static var chevronUpBlue: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronUpBlue)
#else
        return .init()
#endif
    }

    /// The "chevrons-down" asset catalog image.
    nonisolated public static var chevronsDown: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronsDown)
#else
        return .init()
#endif
    }

    /// The "chevrons-left" asset catalog image.
    nonisolated public static var chevronsLeft: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronsLeft)
#else
        return .init()
#endif
    }

    /// The "chevrons-right" asset catalog image.
    nonisolated public static var chevronsRight: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronsRight)
#else
        return .init()
#endif
    }

    /// The "chevrons-up" asset catalog image.
    nonisolated public static var chevronsUp: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .chevronsUp)
#else
        return .init()
#endif
    }

    /// The "cloud-image" asset catalog image.
    nonisolated public static var cloud: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .cloud)
#else
        return .init()
#endif
    }

    /// The "downTriangleBlue" asset catalog image.
    nonisolated public static var downTriangleBlue: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .downTriangleBlue)
#else
        return .init()
#endif
    }

    /// The "edit-3" asset catalog image.
    nonisolated public static var edit3: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .edit3)
#else
        return .init()
#endif
    }

    /// The "edit-profile-button" asset catalog image.
    nonisolated public static var editProfileButton: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .editProfileButton)
#else
        return .init()
#endif
    }

    /// The "emptyLikeAnime" asset catalog image.
    nonisolated public static var emptyLikeAnime: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyLikeAnime)
#else
        return .init()
#endif
    }

    /// The "emptyLikePerson" asset catalog image.
    nonisolated public static var emptyLikePerson: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyLikePerson)
#else
        return .init()
#endif
    }

    /// The "empty_background_img" asset catalog image.
    nonisolated public static var emptyBackgroundImg: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyBackgroundImg)
#else
        return .init()
#endif
    }

    /// The "empty_finished_icon" asset catalog image.
    nonisolated public static var emptyFinishedIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyFinishedIcon)
#else
        return .init()
#endif
    }

    /// The "empty_recent_viewed" asset catalog image.
    nonisolated public static var emptyRecentViewed: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyRecentViewed)
#else
        return .init()
#endif
    }

    /// The "empty_recommendation" asset catalog image.
    nonisolated public static var emptyRecommendation: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyRecommendation)
#else
        return .init()
#endif
    }

    /// The "empty_review_icon" asset catalog image.
    nonisolated public static var emptyReviewIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyReviewIcon)
#else
        return .init()
#endif
    }

    /// The "empty_to_watch_list_icon" asset catalog image.
    nonisolated public static var emptyToWatchListIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .emptyToWatchListIcon)
#else
        return .init()
#endif
    }

    /// The "eyeVisibleIcons" asset catalog image.
    nonisolated public static var eyeVisibleIcons: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .eyeVisibleIcons)
#else
        return .init()
#endif
    }

    /// The "eye_unvisible_Icons" asset catalog image.
    nonisolated public static var eyeUnvisibleIcons: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .eyeUnvisibleIcons)
#else
        return .init()
#endif
    }

    /// The "fill-heart-green" asset catalog image.
    nonisolated public static var fillHeartGreen: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .fillHeartGreen)
#else
        return .init()
#endif
    }

    /// The "fill-pick-star" asset catalog image.
    nonisolated public static var fillPickStar: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .fillPickStar)
#else
        return .init()
#endif
    }

    /// The "filled-heart-pink" asset catalog image.
    nonisolated public static var filledHeartPink: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .filledHeartPink)
#else
        return .init()
#endif
    }

    /// The "googleLoginButton" asset catalog image.
    nonisolated public static var googleLoginButton: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .googleLoginButton)
#else
        return .init()
#endif
    }

    /// The "half-star" asset catalog image.
    nonisolated public static var halfStar: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .halfStar)
#else
        return .init()
#endif
    }

    /// The "heart" asset catalog image.
    nonisolated public static var heart: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .heart)
#else
        return .init()
#endif
    }

    /// The "image" asset catalog image.
    nonisolated public static var image: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .image)
#else
        return .init()
#endif
    }

    /// The "instagramIcon" asset catalog image.
    nonisolated public static var instagramIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .instagramIcon)
#else
        return .init()
#endif
    }

    /// The "instagramIconSmall" asset catalog image.
    nonisolated public static var instagramIconSmall: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .instagramIconSmall)
#else
        return .init()
#endif
    }

    /// The "kakaoLoginButton" asset catalog image.
    nonisolated public static var kakaoLoginButton: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .kakaoLoginButton)
#else
        return .init()
#endif
    }

    /// The "more-horizontal" asset catalog image.
    nonisolated public static var moreHorizontal: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .moreHorizontal)
#else
        return .init()
#endif
    }

    /// The "more-vertical" asset catalog image.
    nonisolated public static var moreVertical: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .moreVertical)
#else
        return .init()
#endif
    }

    /// The "more-vertical-gray" asset catalog image.
    nonisolated public static var moreVerticalGray: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .moreVerticalGray)
#else
        return .init()
#endif
    }

    /// The "recentKeywordClearX" asset catalog image.
    nonisolated public static var recentKeywordClearX: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .recentKeywordClearX)
#else
        return .init()
#endif
    }

    /// The "searchIcons-darkgray" asset catalog image.
    nonisolated public static var searchIconsDarkgray: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .searchIconsDarkgray)
#else
        return .init()
#endif
    }

    /// The "searchIcons-gray" asset catalog image.
    nonisolated public static var searchIconsGray: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .searchIconsGray)
#else
        return .init()
#endif
    }

    /// The "share" asset catalog image.
    nonisolated public static var share: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .share)
#else
        return .init()
#endif
    }

    /// The "shareButton" asset catalog image.
    nonisolated public static var shareButton: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .shareButton)
#else
        return .init()
#endif
    }

    /// The "unSelectIcon" asset catalog image.
    nonisolated public static var unSelectIcon: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .unSelectIcon)
#else
        return .init()
#endif
    }

    /// The "uncheck" asset catalog image.
    nonisolated public static var uncheck: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .uncheck)
#else
        return .init()
#endif
    }

    /// The "unfill-star" asset catalog image.
    nonisolated public static var unfillStar: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .unfillStar)
#else
        return .init()
#endif
    }

    /// The "unfilled-heart" asset catalog image.
    nonisolated public static var unfilledHeart: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .unfilledHeart)
#else
        return .init()
#endif
    }

    /// The "x_button" asset catalog image.
    nonisolated public static var xButton: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .xButton)
#else
        return .init()
#endif
    }

    /// The "x_button_green" asset catalog image.
    nonisolated public static var xButtonGreen: UIKit.UIImage {
#if !os(watchOS)
        return .init(resource: .xButtonGreen)
#else
        return .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif


// MARK: - 테스트용 목록

/// 카탈로그에 있는 에셋 이름. 모든 에셋이 번들에서 로드되는지 테스트에서 확인한다.
enum AssetCatalogIndex {
    nonisolated static let colorNames: [String] = [
        "AnipickBlackColor",
        "AnipickPrimaryColor",
        "AnipickSecondaryColor",
        "BackgroundColor",
        "Gray4Color",
        "Gray5Color",
        "Gray6Color",
        "Gray7Color",
        "Gray8Color",
        "PointColor",
        "SettingSubTitleColor",
        "SettingViewTextColor",
        "TextBlackColor",
        "TextFieldBackgroundColor",
        "TextGrayColor",
        "TextRedColor",
        "ValidNumColor",
    ]
    nonisolated static let imageNames: [String] = [
        "AniPickLogo_green",
        "AniPickLogo_purple",
        "Anipick-logo-green",
        "EmptyViewIcon",
        "GrayToggleOff",
        "GrayToggleOn",
        "Home_filled",
        "Home_unfilled",
        "MyInfo_filled",
        "MyInfo_unfilled",
        "PinkToggle",
        "Ranking_filled",
        "Ranking_unfilled",
        "RecommendView",
        "Reseach_filled",
        "Research_unfilled",
        "SelectIcon",
        "SettingIcon",
        "ToggleDisable",
        "ToggleEnable",
        "UpTrianglePink",
        "alert-circle",
        "all_clear_button",
        "animeThumbnail",
        "animeThumbnailOnlyAdult",
        "appleLoginButton",
        "check",
        "chevron-down-blue",
        "chevron-down-gray",
        "chevron-down-primaryColor",
        "chevron-left",
        "chevron-left-gray",
        "chevron-left-stroke",
        "chevron-right",
        "chevron-up",
        "chevron-up-blue",
        "chevrons-down",
        "chevrons-left",
        "chevrons-right",
        "chevrons-up",
        "cloud-image",
        "downTriangleBlue",
        "edit-3",
        "edit-profile-button",
        "emptyLikeAnime",
        "emptyLikePerson",
        "empty_background_img",
        "empty_finished_icon",
        "empty_recent_viewed",
        "empty_recommendation",
        "empty_review_icon",
        "empty_to_watch_list_icon",
        "eyeVisibleIcons",
        "eye_unvisible_Icons",
        "fill-heart-green",
        "fill-pick-star",
        "filled-heart-pink",
        "googleLoginButton",
        "half-star",
        "heart",
        "image",
        "instagramIcon",
        "instagramIconSmall",
        "kakaoLoginButton",
        "more-horizontal",
        "more-vertical",
        "more-vertical-gray",
        "recentKeywordClearX",
        "searchIcons-darkgray",
        "searchIcons-gray",
        "share",
        "shareButton",
        "unSelectIcon",
        "uncheck",
        "unfill-star",
        "unfilled-heart",
        "x_button",
        "x_button_green",
    ]
}
