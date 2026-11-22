extends Node2D

@export_group("Movimiento")
@export var velocidad := 420.0
@export var gravedad := 2350.0
@export var salto := -720.0
@export var longitud_nivel := 15000.0
@export var suelo_y := 570.0
@export_group("Personaje")
@export var caja_personaje := Vector2(32, 38)
@export var giro_salto := 7.0
@export_group("Modo nave")
@export var gravedad_nave := 950.0
@export var empuje_nave := -1900.0
@export var velocidad_vertical_maxima := 450.0

const NOMBRES := ["Clásico", "Nieve", "Ceniza", "Musgo", "Arena", "Nocturno", "Cobre", "Hielo", "Dorado"]
const COLORES := [Color.WHITE, Color("e6e9e9"), Color("676c75"), Color("789278"), Color("d0b28a"), Color("38465a"), Color("b87955"), Color("9cc9d6"), Color("d6b55d")]

@onready var mundo: Node2D = $Mundo
@onready var arboles: Node2D = $Arboles
@onready var lobo: Sprite2D = $Mundo/PersonajeLobo
@onready var nave: Sprite2D = $Mundo/NaveLobo
@onready var ui: CanvasLayer = $Interfaz

var obstaculos: Node2D
var portales: Node2D
var nivel := 0
var nombres_nivel := ["EL DESPERTAR", "LA CANTERA", "CIELO ELÉCTRICO", "LAS MINAS", "EL END", "CIUDAD PROFUNDA", "BOSQUE NEVADO", "DESIERTO ROJO", "OCÉANO ABISAL", "PUERTA FINAL"]
var mejores := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var modo_nave := false
var impulsando := false
var siguiente_portal := 0

var estado := "menu"
var aspecto := 0
var mejor := 0.0
var muertes := 0
var saltos := 0
var px := 170.0
var py := 546.0
var vy := 0.0
var apoyado := true
var giro := 0.0
var camara := 0.0

func _ready() -> void:
	cargar()
	seleccionar_nivel(nivel)
	ui.get_node("Menu/Jugar").pressed.connect(iniciar)
	ui.get_node("Menu/ElegirNivel").pressed.connect(func(): cambiar_estado("niveles"))
	for i in range(nombres_nivel.size()):
		var indice := i
		ui.get_node("Niveles/Nivel%d" % (i + 1)).pressed.connect(func(): seleccionar_e_iniciar(indice))
	ui.get_node("Niveles/Volver").pressed.connect(func(): cambiar_estado("menu"))
	ui.get_node("Menu/ElegirLobo").pressed.connect(func(): cambiar_estado("selector"))
	ui.get_node("Selector/Anterior").pressed.connect(func(): cambiar_aspecto(-1))
	ui.get_node("Selector/Siguiente").pressed.connect(func(): cambiar_aspecto(1))
	ui.get_node("Selector/Volver").pressed.connect(func(): cambiar_estado("menu"))
	ui.get_node("Pausa/Continuar").pressed.connect(func(): cambiar_estado("jugando"))
	ui.get_node("Pausa/Reiniciar").pressed.connect(iniciar)
	ui.get_node("Derrota/Reintentar").pressed.connect(iniciar)
	ui.get_node("Victoria/Repetir").pressed.connect(iniciar)
	actualizar_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and not event.pressed and event.keycode in [KEY_SPACE, KEY_UP, KEY_W]:
		impulsando = false
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		impulsando = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if estado == "jugando": cambiar_estado("pausa")
			elif estado == "pausa": cambiar_estado("jugando")
			else: cambiar_estado("menu")
		elif event.keycode == KEY_R: iniciar()
		elif event.keycode == KEY_LEFT and estado == "selector": cambiar_aspecto(-1)
		elif event.keycode == KEY_RIGHT and estado == "selector": cambiar_aspecto(1)
		elif event.keycode in [KEY_SPACE, KEY_UP, KEY_W]: activar()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and estado == "jugando": activar()

func activar() -> void:
	match estado:
		"jugando":
			if modo_nave:
				impulsando = true
			elif apoyado:
				vy = salto
				apoyado = false
				saltos += 1
		"menu", "derrota", "victoria": iniciar()
		"pausa": cambiar_estado("jugando")

func iniciar() -> void:
	px = 170.0
	py = suelo_y - 24.0
	vy = 0.0
	apoyado = true
	giro = 0.0
	camara = 0.0
	saltos = 0
	modo_nave = false
	impulsando = false
	siguiente_portal = 0
	cambiar_estado("jugando")

func seleccionar_e_iniciar(indice: int) -> void:
	seleccionar_nivel(indice)
	iniciar()

func seleccionar_nivel(indice: int) -> void:
	nivel = clampi(indice, 0, nombres_nivel.size() - 1)
	$Mundo/Obstaculos.visible = nivel == 0
	$Mundo/Portales1.visible = nivel == 0
	$Arboles.visible = nivel == 0
	for i in range(2, nombres_nivel.size() + 1):
		$Mundo.get_node("Nivel%d" % i).visible = nivel == i - 1
	if nivel == 0:
		longitud_nivel = 15000.0
		obstaculos = $Mundo/Obstaculos
		portales = $Mundo/Portales1
		$Cielo.color = Color("87b8bd")
		$Mundo/Suelo.color = Color("715237")
		$Mundo/Hierba.color = Color("5f9b50")
	else:
		var escena: Node2D = $Mundo.get_node("Nivel%d" % (nivel + 1))
		longitud_nivel = float(escena.get("largo"))
		obstaculos = escena.get_node("Obstaculos")
		portales = escena.get_node("Portales")
		$Cielo.color = escena.color_cielo
		$Mundo/Suelo.color = escena.color_suelo
		$Mundo/Hierba.color = escena.color_hierba
	mejor = mejores[nivel]
	actualizar_ui()

func cambiar_estado(nuevo: String) -> void:
	estado = nuevo
	actualizar_ui()

func cambiar_aspecto(direccion: int) -> void:
	aspecto = posmod(aspecto + direccion, NOMBRES.size())
	guardar()
	actualizar_ui()

func _process(delta: float) -> void:
	if estado == "jugando":
		var paso := minf(delta, 0.033)
		px += velocidad * paso
		comprobar_portales()
		var pie_anterior := py + caja_personaje.y / 2.0
		if modo_nave:
			vy += (gravedad_nave + (empuje_nave if impulsando else 0.0)) * paso
			vy = clampf(vy, -velocidad_vertical_maxima, velocidad_vertical_maxima)
			py += vy * paso
			giro = clampf(vy / velocidad_vertical_maxima * 0.25, -0.25, 0.25)
			if py < 105.0 or py > suelo_y - 43.0: morir()
		else:
			apoyado = false
			vy += gravedad * paso
			py += vy * paso
			if py >= suelo_y - 24.0:
				py = suelo_y - 24.0
				vy = 0.0
				apoyado = true
				giro = roundf(giro / (PI / 2.0)) * (PI / 2.0)
			else: giro += giro_salto * paso
		camara = maxf(0.0, px - 290.0)
		mejor = maxf(mejor, minf(100.0, px / longitud_nivel * 100.0))
		if estado == "jugando": comprobar_colisiones(pie_anterior if not modo_nave else INF)
		if px >= longitud_nivel:
			mejor = 100.0
			mejores[nivel] = 100.0
			guardar()
			cambiar_estado("victoria")
		actualizar_ui()
	mundo.position.x = -camara
	arboles.position.x = -fposmod(camara * 0.22, 2000.0)
	lobo.position = Vector2(px, py)
	lobo.rotation = giro
	lobo.modulate = COLORES[aspecto]
	lobo.visible = estado in ["jugando", "pausa", "derrota", "victoria"] and not modo_nave
	nave.position = Vector2(px, py)
	nave.rotation = giro
	nave.visible = estado in ["jugando", "pausa", "derrota", "victoria"] and modo_nave
	ui.get_node("Selector/VistaPrevia").modulate = COLORES[aspecto]
	ui.get_node("Menu/VistaPrevia").modulate = COLORES[aspecto]

func comprobar_colisiones(pie_anterior: float = INF) -> void:
	var caja := Rect2(Vector2(px, py) - (Vector2(70, 52) if modo_nave else caja_personaje) / 2.0, Vector2(70, 52) if modo_nave else caja_personaje)
	var contorno := PackedVector2Array([caja.position, Vector2(caja.end.x, caja.position.y), caja.end, Vector2(caja.position.x, caja.end.y)])
	for ob in obstaculos.get_children():
		if absf(ob.position.x - px) > 140.0: continue
		if ob.name.begins_with("Pincho") or ob.name.begins_with("Doble") or ob.name.begins_with("Triple") or ob.name.begins_with("Sierra") or ob.name.begins_with("Cristal"):
			for punta in ob.get_children():
				if punta is Polygon2D:
					var triangulo := PackedVector2Array()
					for vertice in punta.polygon: triangulo.append(ob.position + punta.position + vertice)
					if not Geometry2D.intersect_polygons(contorno, triangulo).is_empty():
						morir()
						return
			continue
		var forma: CollisionShape2D = ob.get_node_or_null("Colision")
		if forma == null: continue
		var rect: RectangleShape2D = forma.shape
		var tamano_ob: Vector2 = rect.size * forma.scale
		var caja_ob := Rect2(ob.position + forma.position - tamano_ob / 2.0, tamano_ob)
		if caja.intersects(caja_ob):
			var es_bloque := ob.name.begins_with("Caja") or ob.name.begins_with("Pilar")
			if es_bloque and not modo_nave and vy >= 0.0 and pie_anterior <= caja_ob.position.y + 2.0:
				py = caja_ob.position.y - caja_personaje.y / 2.0
				vy = 0.0
				apoyado = true
				giro = roundf(giro / (PI / 2.0)) * (PI / 2.0)
				caja.position.y = py - caja_personaje.y / 2.0
				contorno = PackedVector2Array([caja.position, Vector2(caja.end.x, caja.position.y), caja.end, Vector2(caja.position.x, caja.end.y)])
				continue
			morir()
			return

func comprobar_portales() -> void:
	var lista := portales.get_children()
	if siguiente_portal >= lista.size(): return
	var portal: Node2D = lista[siguiente_portal]
	if px >= portal.position.x:
		modo_nave = bool(portal.get("activar_nave"))
		impulsando = false
		vy = 0.0
		giro = 0.0
		py = 400.0 if modo_nave else suelo_y - 24.0
		apoyado = not modo_nave
		siguiente_portal += 1

func morir() -> void:
	if estado != "jugando": return
	muertes += 1
	mejores[nivel] = maxf(mejores[nivel], mejor)
	guardar()
	cambiar_estado("derrota")

func actualizar_ui() -> void:
	for nombre in ["Menu", "Selector", "Niveles", "Pausa", "Derrota", "Victoria", "HUD"]:
		ui.get_node(nombre).visible = (nombre.to_lower() == estado or nombre == "HUD" and estado in ["jugando", "pausa", "derrota", "victoria"])
	ui.get_node("Menu/Progreso").text = "Mejor progreso: %d%%  ·  Intentos fallidos: %d" % [int(mejor), muertes]
	ui.get_node("Selector/Nombre").text = "%s  (%d / 9)" % [NOMBRES[aspecto], aspecto + 1]
	ui.get_node("HUD/Barra").value = px / longitud_nivel * 100.0
	ui.get_node("HUD/Porcentaje").text = "%d%%" % int(px / longitud_nivel * 100.0)
	ui.get_node("HUD/Nivel").text = nombres_nivel[nivel]
	ui.get_node("HUD/Modo").text = "MODO NAVE · mantén pulsado para subir" if modo_nave else "MODO LOBO · pulsa para saltar"
	ui.get_node("Menu/Progreso").text = "%s  ·  Mejor: %d%%  ·  Muertes: %d" % [nombres_nivel[nivel], int(mejor), muertes]
	ui.get_node("Derrota/Detalle").text = "Progreso: %d%%  ·  Saltos: %d" % [int(px / longitud_nivel * 100.0), saltos]
	ui.get_node("Victoria/Detalle").text = "Saltos: %d  ·  Intentos fallidos: %d" % [saltos, muertes]

func guardar() -> void:
	var archivo := FileAccess.open("user://progress.json", FileAccess.WRITE)
	if archivo: archivo.store_string(JSON.stringify({"best": mejor, "bests": mejores, "level": nivel, "skin": aspecto, "deaths": muertes}))

func cargar() -> void:
	if not FileAccess.file_exists("user://progress.json"): return
	var datos = JSON.parse_string(FileAccess.get_file_as_string("user://progress.json"))
	if datos is Dictionary:
		mejor = float(datos.get("best", 0.0))
		var guardados = datos.get("bests", [mejor])
		if guardados is Array:
			for i in range(mini(guardados.size(), mejores.size())): mejores[i] = float(guardados[i])
		nivel = clampi(int(datos.get("level", 0)), 0, nombres_nivel.size() - 1)
		aspecto = clampi(int(datos.get("skin", 0)), 0, NOMBRES.size() - 1)
		muertes = int(datos.get("deaths", 0))
