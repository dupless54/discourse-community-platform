import { apiInitializer } from "discourse/lib/api";

const PLATFORM_PATH_PATTERN =
  /^(?:\/(?:home|following|explore|popular)(?:\/|$)|\/s\/[^/?#]+(?:\/|$))/;

export function isCommunityPlatformPath(url) {
  const path = new URL(url, window.location.origin).pathname;
  return PLATFORM_PATH_PATTERN.test(path);
}

export default apiInitializer((api) => {
  const updateShellState = (url) => {
    document.body.classList.toggle(
      "dcp-platform-shell-active",
      isCommunityPlatformPath(url)
    );
  };

  api.onPageChange((url) => updateShellState(url));
  updateShellState(window.location.pathname);
});
