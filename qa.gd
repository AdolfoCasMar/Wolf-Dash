extends SceneTree

func _initialize() -> void:
	call_deferred("verificar")

func verificar() -> void:
	var juego = load("res://main.tscn").instantiate()
	root.add_child(juego)
	for i in range(3):
		juego.seleccionar_e_iniciar(i)
		assert(juego.obstaculos.get_child_count() >= 20)
		assert(juego.portales.get_child_count() >= 2)
		juego.px = juego.portales.get_child(0).position.x + 1.0
		juego.comprobar_portales()
		assert(juego.modo_nave)
		juego.impulsando = true
		var altura_inicial: float = juego.py
		juego._process(0.016)
		assert(juego.py < altura_inicial)
		juego.impulsando = false
		juego.px = juego.portales.get_child(1).position.x + 1.0
		juego.comprobar_portales()
		assert(not juego.modo_nave)
		juego.iniciar()
		var bloque: Node2D
		for candidato in juego.obstaculos.get_children():
			if candidato.name.begins_with("Caja"):
				bloque = candidato
				break
		assert(bloque != null)
		var forma: CollisionShape2D = bloque.get_node("Colision")
		var rect: RectangleShape2D = forma.shape
		var cima: float = bloque.position.y + forma.position.y - rect.size.y * forma.scale.y / 2.0
		juego.px = bloque.position.x + 24.0
		juego.py = cima - juego.caja_personaje.y / 2.0 + 4.0
		juego.vy = 100.0
		juego.comprobar_colisiones(cima - 1.0)
		assert(juego.estado == "jugando" and juego.apoyado)
		juego.px = bloque.position.x - 5.0
		juego.py = cima + 20.0
		juego.vy = 0.0
		juego.comprobar_colisiones(cima + 40.0)
		assert(juego.estado == "derrota")
		if i == 0:
			assert(juego.obstaculos.get_node_or_null("PilarExtra") == null)
			for obstaculo in juego.obstaculos.get_children():
				assert(obstaculo.get_node_or_null("Colision") != null)
				var tiene_forma := false
				for hijo in obstaculo.get_children():
					if hijo is Polygon2D: tiene_forma = true
				assert(tiene_forma)
			juego.iniciar()
			var pincho: Node2D = juego.obstaculos.get_node("Pincho0")
			juego.px = pincho.position.x - 10.0
			juego.py = juego.suelo_y - 50.0
			juego.comprobar_colisiones()
			assert(juego.estado == "jugando")
			juego.px = pincho.position.x + 20.0
			juego.py = juego.suelo_y - 35.0
			juego.comprobar_colisiones()
			assert(juego.estado == "derrota")
	print("QA_OK: sin pilar alto ni colisión invisible en el primer nivel")
	quit()
