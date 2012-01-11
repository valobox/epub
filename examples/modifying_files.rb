require './lib/example'

Example.setup("modifying_files") do |epub|
  # Get the first html item
  item = epub.spine.items.first

  html = <<END
<html>
<body>
  <h1>Hello World</h1>
</body>
</html>
END

  # Replace its contents
  item.write(html)

  puts item.read
end

