Yep — let’s get Astro + npm set up cleanly inside WSL1, in a way that fits your design:

* public repo lives at `~/blog-publish/` (WSL filesystem)
* vault stays on Windows
* `publish.bat` calls into WSL, sets `VAULT_ROOT`, runs `publish.sh`
* Cloudflare Pages builds from the **public repo** (Git)

Below is a straight, repeatable setup.

---

## 0) Preconditions

Inside WSL, make sure you have the basics:

```bash
sudo apt update
sudo apt install -y git rsync build-essential curl
```

---

## 1) Install Node in WSL the sane way (nvm)

Avoid distro node packages. Use `nvm` and pin Node per-repo.

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# restart shell OR:
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"
```

Install a stable Node (I’d use current LTS):

```bash
# nvm install --lts
nvm install 22
# nvm use --lts
nvm use 22
node -v
npm -v
```

---

## 2) Create the public repo folder

```bash
mkdir -p ~/blog-publish
cd ~/blog-publish
git init
```

(Optional but recommended) pin Node for this repo:

```bash
cd ~/blog-publish
node -v | sed 's/^v//' > .nvmrc
```

---

## 3) Create an Astro project in the repo

If you want the Astro scaffolder:

```bash
npm create astro@latest astro-blog -- --template basics
```

Pick:

* “Include sample files?” → your call (I usually say yes once)
* TypeScript → “no” unless you want it
* Install deps → yes

Then:

```bash
cd ~/blog-publish/astro-blog
npm install
npm run dev
```

You should see the local dev server URL. (You don’t *need* dev mode long-term, but it’s good to confirm the toolchain works.)

---

## 4) Set it to static output + correct site URL

Edit `astro.config.mjs`:

```js
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://blog.clueby4.dev',
  output: 'static',
  integrations: [sitemap()],
});
```

Install sitemap integration if you used it:

```bash
npm i @astrojs/sitemap
```

---

## 5) Add RSS

Astro has a built-in RSS helper package; typical pattern is creating `src/pages/rss.xml.js`. We can wire it once your content routing exists (posts list + frontmatter parsing). For now, we just get the toolchain up.

---

## 6) Put your publish scripts into the repo

You already have `publish.sh` in the canvas. In WSL:

```bash
cd ~/blog-publish
chmod +x publish.sh
```

Also ensure your `package.json` has a `build` script (Astro scaffolder does).

---

## 7) Link your Windows vault “publish button”

You already tested `wsl --cd`. Put `publish.bat` in the vault root (Windows) as in the canvas.

Test it:

1. Ensure your vault has `BLOG/` (and `tags.md` if you want)
2. Run `publish.bat`
3. It should:

   * export only `draft:false` posts to `~/blog-publish/BLOG/`
   * generate `llms.txt` (per canvas)
   * `npm run build`
   * commit/push (if you left that enabled)

---

## 8) Cloudflare Pages hookup (later)

Once the public repo is on GitHub:

* create Pages project from repo
* build command: `npm run build`
* output dir: `dist`

---

## One quick “don’t step on rakes” checklist

* **Run Node/npm only in WSL** (repo is on WSL filesystem, so it’ll be fast).
* Keep vault on Windows; export content over.
* Don’t let drafts into public repo (already enforced).
* Pin Node with `.nvmrc` so builds don’t randomly break later.

---

If you tell me whether you want posts rendered from `~/blog-publish/BLOG/<slug>/<slug>.md` directly (simplest) or you prefer to copy them into `src/content/` for Astro’s content collections, I’ll give you the next concrete step: the Astro routing files that render `/<slug>/` plus `/<slug>/index.md` mirrors, and generate RSS from the same metadata.
