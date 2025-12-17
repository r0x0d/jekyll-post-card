# Jekyll Post Card

[![Gem Version](https://badge.fury.io/rb/jekyll-post-card.svg)](https://badge.fury.io/rb/jekyll-post-card)
[![Demo](https://img.shields.io/badge/Demo-Live-brightgreen)](https://r0x0d.github.io/jekyll-post-card/)

A Jekyll plugin to display beautiful, responsive post cards in your Markdown. Works with both internal Jekyll posts and external URLs.

**[📺 View Live Demo](https://r0x0d.github.io/jekyll-post-card/)**

## Features

- 📝 **Internal Posts** - Link to posts within your Jekyll site using permalinks
- 🌐 **External URLs** - Automatically fetches metadata (title, description, image) from any URL
- 🎨 **Multiple Variants** - Default, compact, and vertical card layouts
- 🌙 **Theme Support** - Built-in light and dark theme CSS variables
- 📱 **Responsive** - Cards look great on all screen sizes
- ⚡ **Open Graph & Twitter Cards** - Extracts metadata from standard meta tags

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jekyll-post-card'
```

And then execute:

```bash
bundle install
```

Or install it yourself:

```bash
gem install jekyll-post-card
```

Then add the plugin to your `_config.yml`:

```yaml
plugins:
  - jekyll-post-card
```

## Usage

### Basic Usage

**Internal post (by permalink):**

```liquid
{% post_card /2024/01/15/my-awesome-post %}
```

**External URL:**

```liquid
{% post_card https://dev.to/example/great-article %}
```

### Variants

**Compact card:**

```liquid
{% post_card /my-post variant:compact %}
```

**Vertical card:**

```liquid
{% post_card /my-post variant:vertical %}
```

### Options

**Hide the image:**

```liquid
{% post_card /my-post hide_image:true %}
```

You can combine options:

```liquid
{% post_card /my-post variant:compact hide_image:true %}
```

### Styling

The plugin automatically copies `post-card.css` to your site's `assets/css/` folder during build.

**Add the CSS to your layout:**

```html
<link rel="stylesheet" href="{{ '/assets/css/post-card.css' | relative_url }}">
```

Or import it in your main SCSS file:

```scss
@import "post-card";
```

The CSS uses CSS variables for easy theming:

```css
:root {
  --post-card-bg: #ffffff;
  --post-card-bg-hover: #fff8f0;
  --post-card-text: #2d2a26;
  --post-card-text-secondary: #5a5650;
  --post-card-text-muted: #8a8680;
  --post-card-accent: #d35400;
  --post-card-border: rgba(211, 84, 0, 0.15);
  --post-card-shadow: rgba(45, 42, 38, 0.12);
  --post-card-placeholder-bg: #f0ebe3;
}
```

For dark mode, add the `.dark` class to your body or a parent element, or override the variables.

### Post Front Matter

For internal posts, the plugin reads these front matter fields:

```yaml
---
title: "My Post Title"
excerpt: "A short description of the post"
image: "/images/featured.jpg"  # or thumbnail, og_image
date: 2024-01-15
---
```

### Grid Layouts

Display multiple cards side by side using CSS Grid:

```html
<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px;">
  {% post_card /post-one %}
  {% post_card /post-two %}
</div>
```

## Demo

**[View the live demo →](https://r0x0d.github.io/jekyll-post-card/)**

Or open `demo.html` locally in your browser to see all card variants and layouts.

## Development

After checking out the repo, run `bundle install` to install dependencies.

Run tests:

```bash
bundle exec rake test
```

Build the gem:

```bash
gem build jekyll-post-card.gemspec
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/r0x0d/jekyll-post-card.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

