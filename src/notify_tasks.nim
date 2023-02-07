import markdown

proc main() =
  let html = markdown("# Hello World\nHappy writing Markdown document!")
  echo(html)

main()
