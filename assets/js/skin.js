const SKIN_NAME_KEY = "skinName";

const Skins = {
  Default: "style.css",
  Light: "classic.css",
  Dark: "dark.css",
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

function setSkin(targetSkin) {
  var metaTag = document.getElementById("stylesheet");
  var skinRef = metaTag.href;

  let currentSkin = skinRef.substring(skinRef.lastIndexOf("/") + 1);

  if (targetSkin === undefined) {
    targetSkin = toggleSkinFrom(currentSkin);
  }
  localStorage.setItem(SKIN_NAME_KEY, targetSkin);

  let iconTag = document.getElementById("use-skin-icon");
  let iconRef = iconTag.getAttribute("xlink:href");
  let currentIcon = iconRef.split("#")[1];
  iconTag.setAttribute(
    "xlink:href",
    iconRef.replace(currentIcon, iconForSkin(targetSkin)),
  );

  metaTag.href = skinRef.replace(currentSkin, targetSkin);
}

function loadSkin() {
  let savedSkin = localStorage.getItem(SKIN_NAME_KEY);
  if (savedSkin !== null) {
    setSkin(savedSkin);
  }
}

window.onload = loadSkin;
