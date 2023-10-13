const SKIN_NAME_KEY = "skinName";

const Skins = {
  Default: "follows-system",
  Light: "light",
  Dark: "dark",
};

const Icons = {
  Light: "sun",
  Dark: "moon",
};

function toggleSkinFrom(currentSkin) {
  switch (currentSkin) {
    case Skins.Default: // default, auto
      {
        if (currentSkin == Skins.Default) {
          if (
            window.matchMedia &&
            window.matchMedia("(prefers-color-scheme: dark)").matches
          ) {
            return Skins.Light;
          }

          return Skins.Dark;
        }
      }
      break;
    case Skins.Light:
      return Skins.Dark;
    case Skins.Dark:
      return Skins.Light;
    default:
      console.error(`Unexpected skin ${currentSkin}.`);
  }
}

function iconForSkin(currentSkin) {
  let toggledSkin = toggleSkinFrom(currentSkin);
  console.assert(toggledSkin != Skins.Default, "Didn't expect default skin.");

  switch (toggledSkin) {
    case Skins.Light:
      return Icons.Light;
    case Skins.Dark:
      return Icons.Dark;
    default:
      console.error(`Unexpected skin ${toggledSkin}.`);
  }
}

function applySkin(skin) {
  // https://stackoverflow.com/questions/56300132/
  // how-to-override-css-prefers-color-scheme-setting
  for (var s = 0; s < document.styleSheets.length; s++) {
    for (var i = 0; i < document.styleSheets[s].cssRules.length; i++) {
      rule = document.styleSheets[s].cssRules[i];

      if (
        rule &&
        rule.media &&
        rule.media.mediaText.includes("prefers-color-scheme")
      ) {
        switch (skin) {
          case Skins.Light:
            rule.media.appendMedium("original-prefers-color-scheme");
            if (rule.media.mediaText.includes("light")) {
              rule.media.deleteMedium("(prefers-color-scheme: light)");
            }
            if (rule.media.mediaText.includes("dark")) {
              rule.media.deleteMedium("(prefers-color-scheme: dark)");
            }
            break;
          case Skins.Dark:
            // Our CSS only inlcudes `prefers-color-scheme: dark.
            // So, by adding `prefers-color-scheme: light`
            // we enable it at all times.
            rule.media.appendMedium("(prefers-color-scheme: light)");

            // This is a fix wrt the provided implementation.
            if (!rule.media.mediaText.includes("dark")) {
              rule.media.appendMedium("(prefers-color-scheme: dark)");
            }
            if (rule.media.mediaText.includes("original")) {
              rule.media.deleteMedium("original-prefers-color-scheme");
            }
            break;
          default:
            console.error(`Unexpected skin ${skin}.`);
        }
      }
    }
  }
}

function setSkin(targetSkin) {
  let currentSkin = localStorage.getItem(SKIN_NAME_KEY);
  if (currentSkin === null) {
    currentSkin = Skins.Default;
  }

  if (targetSkin === undefined) {
    targetSkin = toggleSkinFrom(currentSkin);
  }
  localStorage.setItem(SKIN_NAME_KEY, targetSkin);

  setIcon(targetSkin);
  applySkin(targetSkin);
}

function setIcon(targetSkin) {
  let iconTag = document.getElementById("use-skin-icon");
  let iconRef = iconTag.getAttribute("xlink:href");
  let currentIcon = iconRef.split("#")[1];
  iconTag.setAttribute(
    "xlink:href",
    iconRef.replace(currentIcon, iconForSkin(targetSkin)),
  );
}

function migrateSkinName() {
  let savedSkin = localStorage.getItem(SKIN_NAME_KEY);
  switch (savedSkin) {
    // -- before 1f93c2
    case "classic.css":
      localStorage.setItem(SKIN_NAME_KEY, Skins.Light);
      break;
    case "dark.css":
      localStorage.setItem(SKIN_NAME_KEY, Skins.Dark);
      break;
    // -- /before 1f93c2
    case undefined:  // 1f93c2
      localStorage.removeItem(SKIN_NAME_KEY);
      break;
  }
}

function loadSkin() {
  migrateSkinName();

  let savedSkin = localStorage.getItem(SKIN_NAME_KEY);
  if (savedSkin !== null) {
    setSkin(savedSkin); // Also takes care of the icon.
  } else {
    setIcon(Skins.Default);
  }
}

window
  .matchMedia("(prefers-color-scheme: dark)")
  .addEventListener("change", (_) => {
    if (localStorage.getItem(SKIN_NAME_KEY) === null) {
      setIcon(Skins.Default);
    }
  });

window.onload = loadSkin;
