import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';
import type { APIContext } from 'astro';

export async function GET(context: APIContext) {
  const posts = (await getCollection('blog', ({ data }) => data.draft === false))
    .sort((a, b) => (b.data.date?.getTime() ?? 0) - (a.data.date?.getTime() ?? 0));

  return rss({
    title: 'Privileged Contexts',
    description: 'Personal technical blog focused on security, detection/response, and secure use of AI/agentic tooling.',
    site: context.site!.toString(),
    items: posts.map((post) => ({
      title: post.data.title,
      description: post.data.description ?? '',
      link: `/${post.data.slug}/`,
      pubDate: post.data.date ?? new Date(0),
    })),
    customData: '<language>en-us</language>',
  });
}
