Packetloop.Files = {}

Packetloop.Files.getAsText = function (readFile)
{
  var reader = new FileReader()
  reader.onload = Packetloop.Files.loaded
  reader.onerror = Packetloop.Files.errorHandler
  reader.readAsText(readFile)
}

Packetloop.Files.loaded = function(evt)
{
  var fileString = evt.target.result
  Packetloop.Files.fileCallback(fileString)
}

Packetloop.Files.errorHandler = function(evt)
{
  alert('Y U ERROR')
  console.log(evt.target.error)
}

Packetloop.Files.handleFileSelect = function(evt)
{
  evt.stopPropagation()
  evt.preventDefault()
  var files = evt.target.files || evt.dataTransfer.files
  for (var i = 0, f; f = files[i]; i++) {
    Packetloop.Files.getAsText(f)
  }
}

Packetloop.Files.handleDragOver= function(evt)
{
  evt.stopPropagation()
  evt.preventDefault()
  evt.dataTransfer.dropEffect = 'copy'
}

Packetloop.Files.init = function(fileCallback)
{
  Packetloop.Files.fileCallback = fileCallback

  document.getElementById('files').addEventListener('change', Packetloop.Files.handleFileSelect, false)

  var dropZone = document.getElementById('drop_zone')
  dropZone.addEventListener('dragover', Packetloop.Files.handleDragOver, false)
  dropZone.addEventListener('drop', Packetloop.Files.handleFileSelect, false)
}
