import type { CollectionEntry } from "astro:content";
import { SITE } from "@/config";

const postFilter = ({ data }: CollectionEntry<"blog">) => {
  if (data.draft) return false;
  if (!data.date) return false;
  const isPublishTimePassed =
    Date.now() >
    new Date(data.date).getTime() - SITE.scheduledPostMargin;
  return import.meta.env.DEV || isPublishTimePassed;
};

export default postFilter;
