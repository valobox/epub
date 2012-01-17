# README

Library to access and modify the contents of an Epub

![logo](https://github.com/completelynovel/epub/raw/master/logo.png)


## Usage

Initialize with the path to an epub file, note any setters will edit the epub itself, so work on a copy if you don't want to modify the original

    epub = Epub::File.new("9781449315306.epub")


### Structure

An epub is defined into the following parts, the accessor methods are as named below

  * **metadata** - Metadata about to book (title, description etc...)
  * **manifest** - All the files in the epub
  * **guide** - NOT CURRENTLY ACCESSIBLE
  * **spine** - Ordered list of html files in the Epub
  * **toc** - Table of contents which refers to items in the manifest


### Accessing content

The following describes how to access the content, example code for the below is [here](https://github.com/completelynovel/epub/tree/master/examples)


#### Metadata

To access the metadata

    epub.metadata #=> #<Epub::Metadata>

You can set/get metadata in the Epub by using the Hash accessor, for example

    # Getter
    epub.metadata[:title]  #=> "Behind the scenes: Badgers in offices"

    # Setter
    epub.metadata[:description] = "Secret look into the life of Badgers in offices"



#### Manifest

The manifest if the entry point to files in the epub, an Epub usually contains css, html, images and may also contain fonts. There are also some special files which define the structure of the epub which this gem hides from its API.

To access the manifest

    epub.manifest #=> #<Epub::Manifest>

Files within the Epub are refered to as 'items', you can access files directly via the `item` method passing either the *id* of the item in the manifest file or the absolute path to file from the root of the epub zip.

    epub.manifest.get(:id => "cover")              #=> #<Epub::Item>
    epub.manifest.get(:path => "OEBPS/cover.html") #=> #<Epub::Item>


Although its more likely that you don't have this information. To access all items in the Epub

    epub.manifest.items #=> [#<Epub::Item>, #<Epub::Item>, ...]

You can also retrieve them by their type

    epub.manifest.html   #=> [#<Epub::Item>, #<Epub::Item>, ...]
    epub.manifest.css    #=> [#<Epub::Item>, #<Epub::Item>, ...]
    epub.manifest.images #=> [#<Epub::Item>, #<Epub::Item>, ...]
    epub.manifest.misc   #=> [#<Epub::Item>, #<Epub::Item>, ...]

    # Group everything but html (css/images/misc)
    epub.manifest.assets #=> [#<Epub::Item>, #<Epub::Item>, ...]



#### Spine

The spine gives you the ordered list of html items which make up the epub. To access the spine

    epub.spine #=> #<Epub::Spine>
    epub.spine.items #=> [#<Epub::Item>, #<Epub::Item>, ...]



#### Toc (Table of Contents)

To access the toc

    epub.toc #=> #<Epub::Toc>

To retrieve its contents

    epub.toc.as_hash # => Returns a nested hash of:
    # {
    #   :label=>"Colophon",
    #   :url=>"ch01.html#heading1",
    #   :children=>[
    #     # Nested here
    #   ],
    # }

Passing `:normalize => true` will returned the flattened urls if its not already flattened



### Modifing files

When ever you have an instance of a `Epub::Item` you can edit that file in place, for example to modify the first item in the epub

    # Get the first html item
    item = epub.spine.items.first

    # Display its contents
    puts item.read

    html = <<END
    <html>
    <body>
      <h1>Badger badger badger</h1>
      <p>
        Badger badger badger badger badger badger badger badger badger badger badger badger
    Mushroom mushroom
      </p>
    </body>
    </html>"
    END

    # Replace its contents
    item.write(html)



### Normalizing

Calling `normalize!` on an epub will normalise the directory struture, renaming all the urls in the css/html for the items in the manifest.

For example the following directory structure

    /
    |-- META-INF
    |   `-- container.xml
    |-- mimetype
    `-- OEBPS
        |-- random_dir1
            |-- chA.css
            |-- ch01.html
            |-- ch02.html
            |-- image.jpg
        |-- random_dir2
            |-- chB.css
            |-- ch03.html
            |-- ch04.html
            |-- image.jpg
        |-- toc.ncx
        |-- content.opf


Will be normalized into the following format, note the file names get renamed to a MD5 hash of there original absolute filepath to ensure uniqueness

    /
    |-- META-INF
    |   `-- container.xml
    |-- mimetype
    `-- OEBPS
        |-- content.opf
        |-- content
            |-- 899ee1.css  (was chA.css)
            |-- f54ff6.css  (was chB.css)
            |-- c4b944.html (was ch01.html)
            |-- 4e895b.html (was ch02.html)
            |-- 89332e.html (was ch03.html)
            |-- c50b75.html (was ch04.html)
            |-- toc.ncx
            |-- assets
                |-- 5a17aa.jpg (was image.jpg)
                |-- b50b4b.jpg (was image.jpg)


### Compressing

Calling `compress!` will minify all the *css* and *html* items in the epub and compress the images (**IMAGES NOT YET WORKING**). Note the image compression does not reduce quality


## Extracting

If you want to extract an epub, for instance to serve the content up via a web interface you can to the following

    Epub::File.extract('example.epub', '/some/directory/path')


You can also pass a block which will re-zip the epub when the block exits. The block gets passed a <#Epub::File> instance as an argument

    Epub::File.extract('example.epub') do |epub| 
        # Do some epub processing here...
    end



## Development

To get extra logging either run with `ruby -v` which will be very verbose, or if you want just the library log lines run with `LIB_VERBOSE=true`. For example to run the [example scripts](https://github.com/completelynovel/epub/tree/master/examples) with verbose logging do either of the following

    ruby -v normalize.rb
    LIB_VERBOSE=true ruby normalize.rb



## Epub overview (TODO)

An Epub is simply a zip file which has been with the `.epub` extension. Lets take a look at the [example.epub](TODO)

    mkdir extracted
    cp example.epub extracted/example.zip
    cd extracted
    unzip example.zip

You should now have the following file structure

    extracted
    |-- META-INF
    |   `-- container.xml (spec http://idpf.org/epub/20/spec/OCF_2.0.1_draft.doc)
    |-- mimetype
    `-- OEBPS
        |-- random_dir1
            |-- chA.css
            |-- ch01.html
            |-- ch02.html
            |-- image.jpg
        |-- random_dir2
            |-- chB.css
            |-- ch03.html
            |-- ch04.html
            |-- image.jpg
        |-- toc.ncx
        |-- content.opf (spec http://idpf.org/epub/20/spec/OPF_2.0.1_draft.htm)


Explain further...



## Further documentation

Yardoc is used for the documentation, you can start a server and see the docs by running the following command.

    yard server --reload

