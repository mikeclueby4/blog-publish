import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// CONTENT_DIR env var points to a live vault BLOG/ directory in preview mode.
// Falls back to the repo-root BLOG/ (../../BLOG relative to src/).
const contentDir =
  process.env.CONTENT_DIR ?? path.resolve(__dirname, '../../BLOG');

const blog = defineCollection({
  loader: glob({
    pattern: ['*/*.md', '!**/Untitled*'],
    base: contentDir,
  }),
  schema: z.object({
    title: z.string(),
    seo_title: z.string().optional(),
    description: z.string().optional(),
    slug: z.string(),
    canonical: z.string().url().optional(),
    og_image: z.string().optional(),
    tags: z.array(z.string()).default(['security']),
    noindex: z.boolean().default(false),
    draft: z.boolean().default(true),
    date: z.coerce.date().optional(),
    updated: z.coerce.date().optional(),
  }),
});

export const collections = { blog };
