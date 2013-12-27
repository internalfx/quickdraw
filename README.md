# Quickdraw

The idea for Quickdraw comes from the 'shopify_theme' gem. I use a lot of code from them.

### Features

- Uses Ruby 2.0
- MUCH faster downloads and uploads. Unfortunately, Shopify API call limits will slow you down. But in short bursts (10-20 files), Quickdraw is as much as 10x faster or more!
- Quickdraw supports using ERB templates which are compiled then uploaded to shopify. This can save you time when making templates with redundant code.

## Installation

Add this line to your application's Gemfile:

    gem 'quickdraw'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install quickdraw

## Usage

1. Create a project folder and open a terminal
2. run ````quickdraw configure````
3. run ````quickdraw download````
4. run ````quickdraw watch````

### Workflow

Quickdraw creates two folders in your project, ````theme```` and ````src````.
When ````quickdraw watch```` is running, files added/changed/deleted in the ````theme```` folder will be mirrored to Shopify automatically.
To use ERB create a copy of the ````.liquid```` file you want to use, add an ````.erb```` extension to the end, and move it to the ````src```` folder.

#####Example
    project/theme/templates/index.liquid
    project/src/templates/index.liquid.erb

When the ````project/src/templates/index.liquid.erb```` is modified, Quickdraw will render it, overwriting ````project/theme/templates/index.liquid````, and uploading the result to Shopify

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
