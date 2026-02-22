import type { APIRoute, GetStaticPaths } from 'astro';
import { getCollection } from 'astro:content';

// Serves the raw Markdown content at /<slug>/index.md for agent/LLM ingestion.
// Only published (draft: false) posts are served here.
export const getStaticPaths: GetStaticPaths = async () => {
  const posts = await getCollection('blog', ({ data }) => data.draft === false);
  return posts.map((post) => ({
    params: { slug: post.data.slug },
    props: { post },
  }));
};

export const GET: APIRoute = ({ props }) => {
  const { post } = props as Awaited<ReturnType<typeof getStaticPaths>>[number]['props'] & { post: any };
  const body: string = post.body ?? '';
  return new Response(body, {
    headers: {
      'Content-Type': 'text/markdown; charset=utf-8',
    },
  });
};
