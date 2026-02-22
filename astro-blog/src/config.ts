export const SITE = {
  website: "https://blog.clueby4.dev/",
  author: "Mike C",
  profile: "https://blog.clueby4.dev/",
  desc: "Personal technical blog focused on security, detection/response, and secure use of AI/agentic tooling.",
  title: "Privileged Contexts",
  ogImage: "og.png",
  lightAndDarkMode: true,
  postPerIndex: 6,
  postPerPage: 8,
  scheduledPostMargin: 15 * 60 * 1000, // 15 minutes
  showArchives: true,
  showBackButton: true, // show back button in post detail
  editPost: {
    enabled: false,
    text: "Edit page",
    url: "",
  },
  dynamicOgImage: false,
  dir: "ltr", // "rtl" | "auto"
  lang: "en", // html lang code. Set this empty and default will be "en"
  timezone: "America/New_York", // Default global timezone (IANA format) https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
} as const;
