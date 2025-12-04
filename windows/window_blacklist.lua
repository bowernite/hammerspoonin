BLACKLIST_RULES = {{
  app = "Bartender 5"
}, {
  app = "Ice"
}, {
  app = "Archive Utility"
}, {
  app = "iPhone Mirroring"
}, {
  app = "Alfred",
  window = "Alfred"
}, {
  app = "Vivid"
}, {
  app = "Calculator"
}, {
  app = "Captive Network Assistant"
}, {
  window = "Software Update"
}, {
  app = "Security Agent"
}, {
  app = "Homerow"
}, {
  app = "superwhisper"
}, {
  window = "Untitled"
}, {
  app = "coreautha"
}, {
  window = "PayPal - Google Chrome - Brett"
}, {
  -- Google auth window
  window = "Sign in - Google Accounts"
}, {
  -- PayPal payment window
  window = "PayPal"
}, {
  -- Sometimes auth windows don't have titles right away / are "about:blank" (e.g. PayPal)
  window = "about:blank"
}, {
  -- Any Jackbox-related app
  app = "jackbox"
}, {
  window = "jackbox"
}}

-- Function to check if a window is blacklisted
function isWindowBlacklisted(window)
  if not window or not window:application() then
    return true
  end
  local appName = window:application():name()
  local windowName = window:title()

  -- Chrome apps like Notion and Trello for some reason don't have a window name
  if not appName or appName == "" or (not windowName or windowName == "") and
    appName ~= "Notion" and appName ~= "Trello" then
    return true
  end

  if not isMainWindow(window) then
    return true
  end

  for _, rule in ipairs(BLACKLIST_RULES) do
    local ruleIsEmpty = not rule.app and not rule.window
    if ruleIsEmpty then
      return false
    end

    local appMatch = not rule.app or
                       (appName and
                         string.find(string.lower(appName),
          string.lower(rule.app), 1, true))
    local windowMatch = not rule.window or (windowName and
                          string.find(string.lower(windowName),
        string.lower(rule.window), 1, true))
    if appMatch and windowMatch then
      return true
    end
  end
  return false
end
