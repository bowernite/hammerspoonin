return {
    startColimaOnBoot = false,
    -- brew quits these to upgrade, then can't replace them because /Applications isn't writable.
    -- Clear this after scripts are migrated into ~/Applications.
    skipUpgradeCasks = {"alfred", "cleanshot", "betterdisplay", "slack", "google-chrome", "cursor",
                        "obsidian", "spotify", "figma", "superwhisper", "wispr-flow", "kitty",
                        "vivid-app"},
    extraNagNeedles = {"your local password is incorrect"},
    extraSuppressRules = {{
        bundleID = "com.jamf.connect",
        window = "Please sign in using your IG Credentials",
        action = "close"
    }}
}
