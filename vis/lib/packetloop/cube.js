Packetloop.Cube = function() {}

Packetloop.Cube.prototype.init = function(container)
{
  this.container = container
  this.texts = []

  w = container.offsetWidth || window.innerWidth
  h = container.offsetHeight || window.innerHeight

  this.renderer = new THREE.WebGLRenderer({antialias: true})
  this.renderer.setClearColorHex(0x112233, 0.0)
  this.renderer.setSize(w, h)
  container.appendChild(this.renderer.domElement)

  this.scene = new THREE.Scene()

  this.camera = new THREE.PerspectiveCamera(45, w / h, 1, 10000)
  this.camera.position.z = 100
  this.scene.add(this.camera)

  this.controls = new THREE.TrackballControls(this.camera)
  this.controls.target.set(0, 0, 0)
  this.controls.rotateSpeed = 2.0;
  this.controls.zoomSpeed = 1.2;
  this.controls.panSpeed = 0.8;
  this.controls.noZoom = false;
  this.controls.noPan = false;
  this.controls.staticMoving = true;
  this.controls.dynamicDampingFactor = 0.3;
}

Packetloop.Cube.prototype.animate = function()
{
  var projector = new THREE.Projector();
  var _this = this
  this.texts.forEach(function(d) {
    var mesh = d[0]
    var text = d[1]
    var obj = d[2]
    var vector = projector.projectVector(mesh.position.clone(), _this.camera)
    var canvas = _this.renderer.domElement
    vector.x *= canvas.width / 2
    vector.y *= canvas.height / 2
    vector.x += canvas.height / 2
    vector.y += canvas.height / 2
    vector.x += 53 // hax
    vector.y = canvas.height - vector.y
    vector.y -= 20
    obj.css({left: vector.x, top: vector.y})
  })

  this.controls.update()
  this.renderer.clear()
  this.renderer.render(this.scene, this.camera)
}

Packetloop.Cube.prototype.setData = function(data)
{
  this.data = data

  this.data.map(function(d) {
    d[0] = parseFloat(d[0])
    d[1] = parseFloat(d[1])
    d[2] = parseFloat(d[2])
    d[3] = parseFloat(d[3])
  })

  this.xmax = d3.max(this.data, function(d) { return d[0] })
  this.ymax = d3.max(this.data, function(d) { return d[1] })
  this.zmax = d3.max(this.data, function(d) { return d[2] })
  this.vmax = d3.max(this.data, function(d) { return d[3] })
}

Packetloop.Cube.prototype.createCubes = function(data)
{
  var _this = this
  this.setData(data)
  data.forEach(function(d) {
    _this.addCube(d)
  })
}

Packetloop.Cube.prototype.addCube = function(data)
{
  var s = 0.5
  var geometry = new THREE.CubeGeometry(s, s, s)

  var color
  var opac

  if (data[3] == 0) {
    color = 0
    opac = 0.1
  } else {
    color = 0xFF0000
    opac = data[3] / this.vmax + 0.3
  }

  var material = new THREE.MeshBasicMaterial({
    color: color,
    opacity: opac,
    transparent: true,
  })

  mesh = new THREE.Mesh(geometry, material)
  mesh.position.x = data[0] - this.xmax / 2
  mesh.position.y = data[1] - this.ymax / 2
  mesh.position.z = data[2] - this.zmax / 2
  this.scene.add(mesh)

  if (0)
  if (
    (data[0] == 0 || data[0] == this.xmax) &&
    (data[1] == 0 || data[1] == this.ymax) &&
    (data[2] == 0 || data[2] == this.zmax)) {
    var key = data.slice(0, 3).toString().replace(/,/g, '-')
    var a = $(this.container).append('<p id="' + key + '">' + key + '</p>')
    var obj = $('#' + key)
    this.texts.push([mesh, data[0], obj])
  }
}

