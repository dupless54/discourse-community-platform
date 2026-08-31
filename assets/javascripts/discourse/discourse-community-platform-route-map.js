export default function () {
  this.route("community-platform-community", { path: "/s/:slug" });
  this.route("community-platform-home", { path: "/home" });
  this.route("community-platform-popular", { path: "/popular" });
}
