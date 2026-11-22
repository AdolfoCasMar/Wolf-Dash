# Wolf Dash

Descarga para Windows: https://github.com/AdolfoCasMar/Wolf-Dash/releases/download/v0.2.0/WolfDash.exe

Proyecto editable para Godot 4. Abre `project.godot` en Godot y pulsa F5 para jugar. `main.tscn` contiene el primer nivel, el lobo, la nave, los portales y los menús. Cada archivo `nivel2.tscn` a `nivel10.tscn` contiene un nivel adicional con su propia decoración, obstáculos y portales. Puedes seleccionar cada elemento y cambiar colores, formas, posiciones, textos y botones desde el Inspector. En el nodo raíz `WolfDash` puedes ajustar velocidad, gravedad, salto y los parámetros de la nave. Los portales son instancias editables de `portal.tscn`; su propiedad `Activar nave` determina si se entra o sale de ese modo.

## Controles

- Espacio, flecha arriba, W o clic: saltar / confirmar.
- En modo nave, mantén pulsado Espacio, flecha arriba, W o el ratón para subir; suelta para bajar.
- Esc: pausar o volver al menú.
- R: reiniciar.
- Flechas izquierda y derecha: elegir uno de nueve lobos en el selector.

Hay diez niveles seleccionables: «El despertar», «La cantera», «Cielo eléctrico», «Las minas», «El End», «Ciudad profunda», «Bosque nevado», «Desierto rojo», «Océano abisal» y «Puerta final». Los siete niveles nuevos tienen decorados propios dibujados con formas editables; no incluyen recursos gráficos de Minecraft. Los obstáculos incluyen pinchos simples, dobles y triples, cajas, pilares, sierras, cristales y obstáculos de techo. En el primer nivel se eliminó el pilar alto. Los pinchos usan la forma visible de cada triángulo para la colisión. En modo lobo se puede aterrizar y saltar encima de cajas y pilares; tocar sus lados o los pinchos mata. Los portales cambian temporalmente al modo nave y otro portal devuelve al modo lobo. El progreso por nivel, las muertes y el lobo elegido se guardan en `user://progress.json`. `wolf.png` y `nave.png` son las imágenes proporcionadas por el usuario; las nueve opciones aplican tintes al lobo.

## Física

Cada bloque mide 48 píxeles. Velocidad horizontal: 420 px/s (8,75 bloques/s). Impulso vertical: 720 px/s. Gravedad: 2350 px/s². La parábola ideal alcanza 110,3 px (2,30 bloques) y 257,4 px (5,36 bloques) de recorrido horizontal. Es una aproximación jugable al cubo de Geometry Dash a velocidad normal, no una medición certificada ni una reproducción exacta de su física. El escenario está dibujado por código.
