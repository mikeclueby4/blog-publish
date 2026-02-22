import type { CollectionEntry } from "astro:content";

/**
 * Get the URL path for a blog post.
 * Uses the frontmatter `slug` field to build `/<slug>/` URLs.
 * Falls back to the collection id if slug is not set.
 */
export function getPostSlug(post: CollectionEntry<"blog">): string {
  return post.data.slug ?? post.id;
}

/**
 * Get the full href path for a blog post.
 * @returns `/<slug>/`
 */
export function getPath(post: CollectionEntry<"blog">): string {
  return `/${getPostSlug(post)}/`;
}
