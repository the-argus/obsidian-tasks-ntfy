from std/os import walkDirRec, lastPathPart
from std/strutils import endsWith

proc retrieveAllMarkdownFiles*(root: string): seq[string] =
  var files: seq[string] = newSeq[string](0)

  for file in walkDirRec(root, relative=false):
    if file.lastPathPart().endsWith(".md"):
      files.add(file)

  return files
