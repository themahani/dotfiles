// Zen keeps its profile in a randomly named directory under ~/.config/zen,
// so bootstrap doesn't link these. Link this file to <profile>/user.js and
// chrome/userChrome.css to <profile>/chrome/userChrome.css.

// Load chrome/userChrome.css from the profile.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
