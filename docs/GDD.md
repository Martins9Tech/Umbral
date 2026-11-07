# UMBRAL — Documento de Diseño (GDD) v0.1

> **Estado:** preproducción · **Motor:** Godot 4.7 · **Plataforma:** PC (Steam) · **Fecha:** 2026-11-07
> *"Umbral" es el nombre de trabajo; el definitivo se decidirá antes de abrir la página de Steam.*
>
> Documento vivo: cada sección se irá ampliando. Decisiones tomadas y pendientes: [ROADMAP.md](ROADMAP.md#decisiones).

---

## 1. Visión

**Pitch:** un roguelike de supervivencia contra hordas, en 3D con vista isométrica, donde controlas a un campeón con kit propio que combina **habilidades manuales** con un **arsenal automático**, y viajas entre reinos a través de **portales** para derrotar a **jefes con varias fases**.

**Fantasía del jugador:** empiezas débil y terminas siendo una fuerza de la naturaleza que limpia la pantalla, pero con la expresión de habilidad de un MOBA: apuntar, esquivar ataques telegrafiados y elegir el momento de la definitiva.

### 1.1 Pilares de diseño

| # | Pilar | Qué significa en la práctica |
|---|-------|------------------------------|
| 1 | **Poder exponencial legible** | La build crece de forma absurda, pero el jugador siempre entiende qué pasa. Si hay que elegir, la legibilidad gana al espectáculo. |
| 2 | **Identidad de campeón** | Cada campeón cambia *cómo* se juega, no solo sus números. |
| 3 | **Decisiones con sabor** | Cada elección (nivel, aumento, portal) es interesante; nunca hay una opción obviamente correcta. |
| 4 | **Build + manos** | Ganan la build *y* la habilidad: posicionamiento, esquiva, timing de la definitiva. |

### 1.2 Referencias (qué tomar de cada una)

| Juego | Qué tomar |
|-------|-----------|
| Vampire Survivors | Bucle base, armas automáticas, evoluciones, desbloqueos por logros, meta-progresión |
| League of Legends | Kits de campeón, telegrafías en suelo, definitivas, lectura del combate |
| LoL Arena / ARAM: Caos | Aumentos por rareza, sets de aumentos, mutadores exagerados |
| Hades | Sinergias entre bendiciones, elegir puerta viendo la recompensa, dificultad opcional (Pacto), narrativa entre runs |
| Risk of Rain 2 | "Director" de spawns por créditos; teleportador → jefe → siguiente mapa |
| Halls of Torment / Death Must Die / Soulstone Survivors | Survivors con builds más profundas y habilidades activas |
| Megabonk | Survivors-like en 3D: cómo mantener la legibilidad en 3D |
| Brotato | Tienda dentro de la run; personajes que cambian las reglas |
| Diablo | Afijos de élites |

> ⚠️ **Ojo:** Riot ya publicó un modo de LoL de este estilo, *Swarm* (Operación: Escuadrón Anima, 2024). Conviene jugarlo y estudiarlo, precisamente para **diferenciarse** de él.

### 1.3 Cómo no parecer una copia de LoL

- **Kit con estructura propia**, distinta de Q/W/E/R + pasiva (ver §4).
- **Mundo, nombres y terminología propios.** Evitar: Nexo, Grieta, Invocador, Barón, Hextech, Vacío, súbditos, etc.
- **Aumentos con nombres y efectos propios**: nos inspiramos en la *estructura* (rareza, sets), no en el contenido.
- **Estética propia**: paleta, siluetas y estilo definidos por nosotros.
- **Control WASD/mando** en lugar de clic para moverse: el combate se siente distinto desde el primer segundo.

---

## 2. Bucles de juego

### 2.1 Bucle en partida (segundo a segundo)

```
Moverse / esquivar → las armas automáticas matan → caen gemas de XP
      ↑                                                     ↓
hordas más fuertes ← más poder ← elegir mejora ← subir de nivel
      ↓
élites → cofres · aumentos · eventos → JEFE → PORTAL
```

### 2.2 Bucle de expedición (una run, unos 40 min)

```
La Encrucijada (hub) → elegir campeón + reino inicial (+ pactos opcionales)
 → Reino 1 (~12 min) → Jefe → elegir entre 2-3 portales
 → Reino 2 → Jefe → portales
 → Reino 3 → Jefe → Corazón del Umbral (jefe final)
 → recompensas → hub
```

### 2.3 Bucle meta (entre runs)

Runs → Esencia + logros → desbloquear campeones, armas en el pool, reinos/portales y mejoras permanentes → runs más variadas.

### 2.4 Modos de juego

| Modo | Descripción | Cuándo |
|------|-------------|--------|
| **Expedición** (principal) | 3 reinos + reino final, eligiendo ruta por portales | Base |
| **Supervivencia clásica** | 1 reino, 20-30 min, al estilo Vampire Survivors. Al final "se cierra el Umbral": aparece una entidad imparable | Base |
| **Caos** | Run con mutadores de caos activos y aumentos acelerados (homenaje a ARAM: Caos) | Desbloqueable |
| Desafío diario, Infinito, Co-op | Ver §13 | Futuro |

---

## 3. Mundo y premisa (ligera)

Hace siglos el mundo se partió en **Reinos** flotantes, unidos por **Umbrales** (portales). Algo del otro lado, **la Marea**, se filtra por ellos en forma de hordas. Los **Portadores**, héroes de cada reino capaces de canalizar el poder de los Umbrales, se reúnen en **La Encrucijada** para cerrar las brechas una a una.

- La narrativa se cuenta con poco texto: diálogos breves en el hub entre runs (al estilo Hades) y entradas del Códice.
- Cada Portador viene de un reino distinto, y eso justifica la variedad de estilos y facciones.

---

## 4. Campeones (Portadores)

### 4.1 Estructura del kit: "Kit de 4 piezas"

En vez de copiar Q/W/E/R + pasiva, cada campeón tiene **4 piezas** más una esquiva común a todos:

| Pieza | Activación | Rol | Progresión en la run |
|-------|-----------|-----|----------------------|
| **Rasgo** | Pasivo, siempre activo | Define el estilo de juego del campeón | Se potencia al completar el **Hito** del campeón |
| **Arma de firma** | Automática | Arma inicial exclusiva, con hueco propio | Niveles 1-8 y evolución propia |
| **Técnica** | Manual, enfriamiento corto (4-8 s) | Movilidad o utilidad, apuntada | Rangos 1-5; en el rango 3 se elige una **Mutación** |
| **Definitiva** | Manual, se carga con **Ímpetu** (matar, recibir daño, recoger gemas) | Momento de poder | Rangos 1-3 y **Despertar** |
| *Paso* (común) | Manual, ~3 s de enfriamiento | Esquiva corta | Lo modifican aumentos y reliquias |

**Por qué así y no con 4 habilidades:** en un juego de hordas la atención está en el movimiento. Dos botones de habilidad más la esquiva son el punto justo: se nota la habilidad del jugador sin competir con las armas automáticas. La Definitiva cargada por Ímpetu (y no por tiempo) premia jugar agresivo y la diferencia de LoL.

**Accesibilidad:** cada habilidad tiene una opción de *autolanzamiento*, para jugar solo con movimiento como en Vampire Survivors.

### 4.2 Mutaciones, Despertares e Hitos

- **Mutación** (Técnica, rango 3): se elige 1 de 3 variantes que cambian el comportamiento, no solo los números. Ejemplo: una embestida que pasa a dejar un muro, o a tener 3 cargas.
- **Despertar** (Definitiva, rango 3 + condición): versión evolucionada con otro efecto visual. La condición puede ser una reliquia concreta o un aumento de un set concreto.
- **Hito del campeón**: un objetivo propio dentro de la run (p. ej. "absorbe 5.000 de daño"). Al cumplirlo, el Rasgo se potencia. Da un objetivo secundario distinto a cada campeón.

### 4.3 Arquetipos

Tanque · Mago · Asesino · Tirador · Invocador · Control/daño en el tiempo · *(Soporte, pensado para el co-op futuro)*

### 4.4 Plantel inicial (6 campeones originales)

#### Orrun, el Monolito Errante — *Tanque, cuerpo a cuerpo*
Fantasía: una montaña que camina.
- **Rasgo, Raíz Profunda:** si se queda quieto 1 s, gana capas de Piedra (−5 % de daño recibido por capa, máx. 5). Al volver a moverse, libera una onda sísmica que crece con las capas. Invita a jugar a "plantarse y soltar".
- **Arma de firma, Puño Telúrico:** golpe en cono contra el enemigo más cercano; empuja.
- **Técnica, Zancada de Falla:** embestida en la dirección apuntada que deja una grieta que ralentiza.
  - Mutaciones: *Muro de Basalto* (la grieta se convierte en un muro que bloquea enemigos) / *Réplica* (3 cargas cortas) / *Erupción* (la grieta explota a los 2 s).
- **Definitiva, Despertar del Monte:** durante 6 s queda inmóvil e invulnerable y lanza un terremoto por segundo en un radio enorme.
  - Despertar *Cordillera:* al terminar, deja picos de roca durante 20 s que dañan y bloquean.
- **Hito:** absorber 5.000 de daño → Raíz Profunda llega a 8 capas.

#### Sela Voltaria, la Tormenta Encadenada — *Maga, a distancia*
- **Rasgo, Sobrecarga:** cada impacto de rayo da 1 carga. Con 20 cargas, la siguiente Técnica desata una tormenta de 8 rayos.
- **Arma de firma, Arco Voltaico:** rayo que salta entre 3 enemigos.
- **Técnica, Salto Iónico:** teletransporte corto que deja una esfera eléctrica que pulsa durante 3 s.
  - Mutaciones: *Doble Salto* (2 cargas) / *Satélite* (la esfera te sigue) / *Singularidad* (la esfera atrae a los enemigos).
- **Definitiva, Ojo de la Tormenta:** durante 8 s, un aura móvil a tu alrededor donde caen rayos.
  - Despertar *Tempestad Perpetua:* cada enemigo que muere dentro del aura alarga su duración.
- **Hito:** matar a 300 enemigos con rayos encadenados → todas las armas de Rayo ganan +2 saltos.

#### Nyra, Ladrona de Ecos — *Asesina / utilidad*
- **Rasgo, Eco Robado:** al matar élites o superar fases de un jefe, roba un **Eco** (una habilidad de ese enemigo) que puede lanzar después (máx. 2 cargas). Conocer a los enemigos forma parte de su build.
- **Arma de firma, Dagas Gemelas:** abanico de dagas en la dirección de movimiento; los críticos ejecutan a enemigos por debajo del 10 % de vida.
- **Técnica, Paso Sombrío:** 1 s intangible atravesando enemigos; los atravesados quedan *Marcados* (reciben más daño).
- **Definitiva, Mil Reflejos:** crea 4 reflejos que copian sus armas durante 7 s.
- **Hito:** 50 ejecuciones → los Ecos llegan a 3 cargas.

#### Brann Hollín, el Forjador — *Invocador / ingeniero*
- **Rasgo, Taller Ambulante:** mientras está cerca de uno de sus Yunques, todas sus armas automáticas cuentan como +1 nivel.
- **Arma de firma, Martillo Rebotador:** martillo que rebota entre enemigos y vuelve.
- **Técnica, Yunque:** planta un yunque-torreta (máx. 2) que dispara y marca la zona del Rasgo.
- **Definitiva, Fundición:** durante 10 s, todas sus armas funcionan como su versión evolucionada.
- **Hito:** recoger 1.000 de oro → tercer Yunque.

#### Ixa, Tejedora de Micelio — *Control de zona / daño en el tiempo*
- **Rasgo, Colonia:** los enemigos que mueren envenenados dejan una espora que contagia a los cercanos.
- **Arma de firma, Nube de Esporas:** nubes venenosas en posiciones cercanas.
- **Técnica, Alfombra Viva:** extiende micelio en un área; ralentiza a los enemigos y te cura mientras estás encima.
- **Definitiva, Floración:** todas las esporas y nubes del mapa detonan a la vez.
- **Hito:** tener 100 enemigos envenenados a la vez → el veneno se acumula sin límite.

#### Vesk, Arponero de las Mareas — *Tirador*
- **Rasgo, Corriente:** moverse en la misma dirección acumula Corriente (+velocidad de ataque). Un giro brusco la consume en un disparo potenciado.
- **Arma de firma, Ballesta de Arpones:** proyectil perforante en línea recta.
- **Técnica, Arpón Cadena:** engancha a un enemigo grande (te lleva hacia él) o a varios pequeños (los arrastra hacia ti).
- **Definitiva, Marea Viva:** una ola gigante barre la pantalla en la dirección apuntada, empujando y dañando.
- **Hito:** recorrer 5 km → la Corriente ya no se pierde al recibir daño.

> Las Mutaciones y Despertares de Nyra, Brann, Ixa y Vesk se definirán más adelante.

### 4.5 Desbloqueo y maestría
- Al principio hay 2 campeones disponibles (Orrun y Sela); el resto se desbloquea con logros ("Derrota a La Madre Raíz", "Sobrevive 10 min sin usar la Técnica"…) o con Esencia.
- **Maestría por campeón** (niveles 1-10): desbloquea un arma de firma alternativa, un Rasgo alternativo, aspectos y títulos.

---

## 5. Progresión dentro de la partida

Varias capas de mejora, cada una con su ritmo:

| Capa | Frecuencia | Qué aporta | Inspiración |
|------|-----------|------------|-------------|
| Subida de nivel | Muy alta | Armas, reliquias, rangos de habilidad | Vampire Survivors |
| Cofres | Tras élites | Mejoras extra y evoluciones | Vampire Survivors |
| **Aumentos** | Min. 4 y 8 de cada reino y tras cada jefe | Cambian reglas; 3 rarezas | Arena |
| **Sinergias** | Pasiva | Bonos 2/4/6 por etiquetas | Sets de Arena / TFT |
| Mercader y altares | Eventos | Comprar con oro, sacrificios | Brotato / Hades |
| **Mutadores de Caos** | Opcional / eventos | Efectos locos con contrapartida | ARAM: Caos |
| Pactos | Antes de la run | Más dificultad a cambio de recompensa | Pacto de Hades |

### 5.1 Experiencia y subida de nivel
- Gemas de XP de colores según su valor; las recoge el radio del **imán**.
- Al subir de nivel, eliges 1 de 3 opciones (4 con ciertas reliquias o aumentos): arma nueva, subir un arma, reliquia nueva, subir una reliquia, o subir el rango de la Técnica o la Definitiva.
- Herramientas de control: **Volver a tirar**, **Saltar** (da oro) y **Desterrar** (quita esa opción del pool en esta run).
- Curva rápida al principio (nivel 10 en unos 3 min) y más lenta después.

### 5.2 Armas automáticas
- **Huecos:** arma de firma + 5 armas. **Niveles:** 1-8.
- **Etiquetas:** un elemento (Fuego, Hielo, Rayo, Veneno, Sombra, Luz, Físico) y una forma (Proyectil, Área, Orbital, Invocación, Cuerpo a cuerpo, Trampa).

Pool inicial propuesto (16):

| Arma | Etiquetas | Comportamiento |
|------|-----------|----------------|
| Cuchillas Orbitales | Físico · Orbital | Giran alrededor del campeón |
| Mortero Alquímico | Fuego · Área | Proyectiles en arco que dejan fuego |
| Cadena de Escarcha | Hielo · Proyectil | Rebota entre enemigos y ralentiza |
| Bumerán de Hueso | Físico · Proyectil | Va y vuelve atravesando |
| Campana Resonante | Físico · Área | Onda expansiva periódica que empuja |
| Polillas de Luz | Luz · Invocación | Enjambre que busca enemigos |
| Lanza Celeste | Luz · Proyectil | Perfora hacia el enemigo con más vida |
| Minas de Brea | Fuego · Trampa | Minas que arden al explotar |
| Látigo de Zarzas | Veneno · Cuerpo a cuerpo | Barrido lateral que envenena |
| Pararrayos | Rayo · Trampa | Postes que lanzan rayos a los cercanos |
| Esquirlas Umbrías | Sombra · Proyectil | Proyectiles teledirigidos |
| Aura Gélida | Hielo · Área | Aura constante que daña y ralentiza |
| Cuervos de Ceniza | Sombra · Invocación | Cuervos que atacan y roban vida |
| Meteoro | Fuego · Área | Lento, enorme y devastador |
| Escudo de Espinas | Físico · Orbital | Bloquea proyectiles y devuelve daño |
| Gota Ácida | Veneno · Proyectil | Deja charcos corrosivos |

### 5.3 Reliquias (pasivas de estadísticas)
**Huecos:** 5. **Niveles:** 1-5.

Poder (daño) · Amplitud (área) · Celeridad (velocidad de proyectil) · Persistencia (duración) · Presteza (enfriamiento) · Multiplicidad (cantidad) · Vigor (vida máx.) · Savia (regeneración) · Coraza (armadura) · Magnetismo (imán) · Fortuna (suerte) · Sabiduría (XP) · Codicia (oro) · Zancada (velocidad) · **Maldición** (más enemigos, más rápidos y más recompensas).

### 5.4 Evoluciones
- **Regla:** arma al nivel 8 + reliquia concreta (a cualquier nivel) → el siguiente cofre de élite la evoluciona.
- Ejemplos:
  - Cuchillas Orbitales + Multiplicidad → **Danza de Mil Filos**
  - Mortero Alquímico + Amplitud → **Lluvia de Magma**
  - Cadena de Escarcha + Persistencia → **Invierno Eterno**
  - Campana Resonante + Vigor → **Campana del Juicio** (su daño escala con la vida máx.)
- Cada arma de firma tiene su propia evolución.
- El **Códice** registra las evoluciones descubiertas; buscarlas es parte del atractivo.
- *(Futuro)* **Fusiones:** dos armas al máximo se combinan en una y liberan un hueco.

### 5.5 Aumentos (inspirados en Arena)
- **Cuándo:** en los minutos 4 y 8 de cada reino y al derrotar a cada jefe. Eliges 1 de 3, con 1 recambio gratis por ronda.
- **Rarezas:** **Eco** (sencillos) → **Arcano** (cambian una mecánica) → **Mítico** (rompen reglas). La probabilidad de las rarezas altas sube con la profundidad.
- Algunos aumentos pertenecen a un **set**: reunir 2 o 3 del mismo set da un bono extra.

| Rareza | Aumento | Efecto |
|--------|---------|--------|
| Eco | Piel de Corteza | +15 % vida máx.; al recibir daño, 1 s de armadura extra |
| Eco | Ojo Avizor | +10 % probabilidad de crítico |
| Eco | Botín Fácil | +20 % de oro de los enemigos |
| Eco | Segundo Aliento | Al bajar del 30 % de vida, te curas un 20 % (una vez por reino) |
| Arcano | Eco Doble | La Técnica se repite 0,5 s después con el 50 % de efecto |
| Arcano | Combustión | Los enemigos que mueren quemados explotan |
| Arcano | Gravedad | Tus proyectiles atraen ligeramente a los enemigos |
| Arcano | Cadena de Mando | Cada muerte reduce 0,1 s el enfriamiento de la Técnica |
| Mítico | Todo o Nada | Críticos ×4, pero ya no regeneras vida |
| Mítico | Espejo Roto | Cada arma dispara además una copia en dirección opuesta |
| Mítico | Definitiva Perpetua | La Definitiva se carga sola cada 20 s, pero dura la mitad |
| Mítico | Coloso | +50 % tamaño, +60 % vida y área, −20 % velocidad |

### 5.6 Sinergias por etiquetas
Cada arma y cada aumento tienen etiquetas. Al reunir varias iguales se activan bonos por umbral:

| Etiqueta | 2 | 4 | 6 |
|----------|---|---|---|
| Fuego | Quemadura +50 % duración | Los quemados explotan al morir | El fuego se propaga entre enemigos |
| Hielo | +20 % ralentización | Congelar tras 3 golpes | Los congelados reciben ×2 de daño |
| Rayo | +1 salto | Electrocutar aturde 0,3 s | Cada 10 s cae una tormenta sobre el grupo más denso |
| Veneno | +1 acumulación máx. | El veneno reduce la armadura | Los envenenados se contagian entre sí |
| Sombra | +10 % crítico | Ejecuta por debajo del 8 % | Los críticos generan esquirlas |
| Orbital | +1 orbital | +30 % velocidad de giro | Los orbitales disparan proyectiles |

*(Futuro)* **Reacciones elementales:** Quemado + Congelado = *Choque Térmico* (gran daño); Mojado + Rayo = *Electrocución* en cadena; etc.

### 5.7 Economía en partida
- **Oro:** lo sueltan enemigos, cofres y objetos destructibles.
  - **Mercader Errante** (una vez por reino): vende armas, reliquias, recambios, curación y un aumento caro.
  - **Altares:** ver §5.8.
- Al terminar la run, parte del oro se convierte en **Esencia** (moneda permanente).

### 5.8 Eventos del mapa
- **Altar de Sangre:** sacrificas un 20 % de vida máx. a cambio de un aumento Arcano.
- **Santuario de Caos:** aceptas un Mutador de Caos aleatorio a cambio de una recompensa Mítica.
- **Contrato:** "mata a 150 enemigos en 30 s" → cofre.
- **Cofre Maldito:** más recompensa, pero invoca élites.
- **Hordas especiales:** anillo que se cierra, estampida, eclipse (visión reducida).
- **Objetos destructibles** (braseros, cristales…) con objetos clásicos del género: comida, imán total, bomba de pantalla, reloj (congela a los enemigos).

### 5.9 Mutadores de Caos (inspirados en ARAM: Caos)
Modificadores exagerados que afectan **a todo** (a ti y a los enemigos), con ventaja y contrapartida:

- **Gravedad Lunar:** los proyectiles van en arco y todo flota; los empujes son enormes.
- **Bola de Nieve:** los enemigos que matas salen rodando y arrastran a otros.
- **Ruleta:** cada 60 s tu Definitiva se cambia por la de otro campeón.
- **Gigantes y Enanos:** cada enemigo tiene un tamaño aleatorio (más grande = más vida y más XP).
- **Fiebre del Oro:** todo suelta oro, pero el oro explota si no lo recoges en 3 s.
- **Doble Sombrío:** te persigue una copia oscura de ti con tus armas.
- **Hiperactividad:** todo va al 130 % de velocidad, tú incluido.
- **Lluvia de Aumentos:** un aumento cada 2 min, pero solo Míticos con una desventaja.

**Modo Caos:** una run con 3 mutadores activos y aumentos acelerados, con recompensas ×2.

### 5.10 Pactos (dificultad opcional)
Antes de la run puedes activar pactos: enemigos con más vida, élites más frecuentes, jefes con una fase extra, menos curación… Cada pacto suma **Rango de Pacto**, que da más Esencia y recompensas exclusivas (aspectos, títulos, logros).

---

## 6. Reinos, portales y hub

### 6.1 Hub: La Encrucijada
- **Sala de Portales:** elegir expedición o reino; cada portal se enciende al desbloquearse.
- **Salón de Campeones:** selección, maestría y aspectos.
- **Armería:** mejoras permanentes con Esencia.
- **Códice:** bestiario, armas, evoluciones y aumentos descubiertos.
- **Tablón:** logros y desafíos semanales.
- **Campo de pruebas:** maniquíes para probar campeones y armas.

> Recomendación: empezar con un hub en forma de menú y convertirlo en una escena 3D explorable más adelante.

### 6.2 Reinos

| # | Reino | Ambiente | Mecánica del mapa | Facción | Jefe |
|---|-------|----------|-------------------|---------|------|
| 1 | **Bosque de los Susurros** | Bosque otoñal con niebla mágica | Oleadas de niebla que reducen la visión; árboles que bloquean | Bestias corruptas, setas andantes | La Madre Raíz |
| 2 | **Ruinas Anegadas** | Templo hundido | Agua que ralentiza y moja (el Rayo hace más daño); mareas que cambian el terreno | Crustáceos, ahogados | Kraal, el Leviatán de Coral |
| 3 | **Forja de Brasas** | Volcán industrial | Ríos de lava, géiseres periódicos, cintas transportadoras | Autómatas, gólems de escoria | El Capataz Ígneo |
| 4 | **Páramo de Cristal** | Tundra con cristales | Hielo resbaladizo (inercia); cristales que reflejan proyectiles | Espectros de escarcha, cristálidos | El Centinela Glacial |
| 5 | **Ciudad Celeste** | Ciudad flotante en ruinas | Puentes que colapsan, viento que empuja | Autómatas alados, sectarios | El Arconte Caído |
| 6 | **Corazón del Umbral** (final) | El espacio entre reinos | El suelo se reconfigura en cada fase | La Marea pura | El Devorador de Umbrales |

**Tamaño:** mapas grandes con límites (6-10 pantallas de ancho), construidos con un kit modular por reino y con puntos de interés colocados de forma semialeatoria en cada run. Dan más variedad y control que un mapa infinito y son más baratos de producir en 3D.

### 6.3 Portales

1. **Portales del hub (meta):** cada reino tiene su portal en La Encrucijada. Se desbloquea al derrotar al jefe del reino anterior o al cumplir una condición ("sobrevive 10 min en el Bosque").
   - **Portales secretos:** reinos ocultos con condiciones escondidas (p. ej. *El Jardín Invertido*, al completar el Bosque con un Mutador concreto).
2. **Portales en partida (ruta):** al derrotar al jefe de un reino se abren 2-3 portales hacia los siguientes reinos disponibles, cada uno con su **recompensa visible**:
   - Aumento Mítico garantizado · Mercader · Cofre de evolución · **Portal de Caos** (mutador + recompensa doble) · Portal Élite (más peligro, más botín).
3. **Grietas de bonus:** dentro de un reino, al cumplir algo (romper 10 cristales, matar a un élite raro) se abre un mini-reino de 1-2 min (cámara del tesoro o desafío) y luego vuelves.

**Escalado por profundidad:** la dificultad depende del número de reino en la ruta, no del reino en sí. Así cualquier reino puede ser el 1.º o el 3.º y las rutas varían de verdad.

### 6.4 Fases de un reino (línea de tiempo, ~12 min)

| Tiempo | Fase | Qué pasa |
|--------|------|----------|
| 0:00-2:00 | **Llegada** | Enemigos básicos y densidad baja; aprender el terreno |
| 2:00 | Primer élite | Cofre |
| 4:00 | **Aumento #1** | |
| 4:00-6:00 | **Escalada** | Nuevos tipos (a distancia, cargadores); evento del mapa |
| 6:00 | **Heraldo** (mini-jefe) | Élite gigante que anticipa una mecánica del jefe |
| 8:00 | **Aumento #2** + Mercader | |
| 8:00-10:00 | **Clímax** | Horda máxima y evento especial (eclipse, estampida) |
| 10:00 | **Convocatoria** | La horda se retira, se forma la arena y aparece el jefe |
| Jefe vencido | **Umbral** | Cofre del jefe + aumento + elección de portal |

> **Variante a probar:** que el jugador invoque al jefe cuando quiera desde un *Altar del Umbral* (a partir del minuto 8). Cada minuto extra sube la dificultad y las recompensas, como el teleportador de Risk of Rain.

---

## 7. Jefes y fases

### 7.1 Principios
- **Legibilidad:** telegrafías en el suelo, sonido de aviso y animación de anticipación. Un color reservado solo para los peligros del jefe.
- **La horda se calma** durante el jefe, o pasa a formar parte de la mecánica (adds invocados).
- **Fases por umbral de vida** (p. ej. 100-70 / 70-40 / 40-0), con transición: 2 s invulnerable, mini-cinemática y cambio en la arena.
- Cada fase **añade 1 mecánica** y combina las anteriores.
- **Furia suave:** si el combate se alarga, el jefe acelera.
- Ninguna build razonable queda anulada: sin inmunidades totales a elementos; los controles se reducen en duración, pero no se anulan.
- Barra de vida con **marcas de fase** visibles.

### 7.2 Ejemplo detallado: La Madre Raíz (Bosque de los Susurros)
- **Fase 1 (100-70 %):** arraigada en el centro. Raíces que brotan bajo el jugador (círculos telegrafiados), barrido de ramas en cono y hojas cortantes en espiral.
- **Transición:** grito; el borde de la arena se llena de zarzas y la arena se reduce.
- **Fase 2 (70-40 %):** invoca Brotes que, si no mueren en 10 s, se convierten en árboles que la curan. Raíces en líneas cruzadas.
- **Fase 3 (40-0 %):** se arranca del suelo y te persigue dejando un rastro de espinas, con embestidas telegrafiadas.
- **Último aliento (10 %):** lluvia de semillas por toda la arena; hay que ponerse a cubierto en los anillos seguros.

### 7.3 Resto de jefes (resumen)
- **Kraal, el Leviatán de Coral:** entra y sale del agua (solo es vulnerable en superficie). Fase 2: sube la marea y la arena queda en islas. Fase 3: tormenta y remolino que atrae.
- **El Capataz Ígneo:** se sobrecalienta; al cerrar las válvulas de la arena queda expuesto. Fase 2: cintas transportadoras activas. Fase 3: la lava inunda la arena por sectores.
- **El Centinela Glacial:** escudo de cristal que se rompe con daño sostenido. Fase 2: refleja proyectiles. Fase 3: congela el suelo (patinaje).
- **El Arconte Caído:** combate vertical; las plataformas colapsan y crea copias de sí mismo.
- **El Devorador de Umbrales (final):**
  - Fase 1: usa ataques de los jefes de *tu* ruta.
  - Fase 2: **te roba uno de tus aumentos**; lo recuperas al romper su núcleo.
  - Fase 3: el suelo cambia entre los reinos que has visitado.
  - Final: la Marea total; sobrevive 60 s con la Definitiva recargándose ×3.

### 7.4 Heraldos y élites
- **Heraldo:** mini-jefe que anticipa una mecánica del jefe del reino.
- **Élites:** enemigos normales con 1-2 **afijos**: Veloz, Blindado (escudo frontal), Vampírico, Explosivo al morir, Invocador, Fantasmal (atraviesa obstáculos), Reflectante, Furioso (enloquece con poca vida). Los afijos más complejos aparecen en reinos profundos.

---

## 8. Enemigos

### 8.1 Arquetipos de comportamiento (reutilizables entre facciones)

| Arquetipo | Comportamiento | Función de diseño |
|-----------|---------------|-------------------|
| Enjambre | Van directos, débiles | Masa, XP, sensación de poder |
| Corredor | Rápidos, poca vida | Obligan a moverse |
| Bruto | Lentos, mucha vida, empujan | Bloquean el paso |
| Tirador | Guardan distancia; proyectiles lentos y visibles | Obligan a esquivar |
| Cargador | Telegrafía una embestida en línea | Lectura y reflejos |
| Explosivo | Corre hacia ti y explota (zona telegrafiada) | Castiga quedarse quieto |
| Divisor | Al morir se divide | Densidad |
| Chamán | Potencia o cura a los cercanos | Prioridad de objetivo |
| Excavador | Emerge bajo tierra cerca de ti (telegrafiado) | Sorpresa controlada |

Cada facción = estos arquetipos con su propia apariencia + 1-2 arquetipos únicos del reino.

### 8.2 Director de oleadas
- Cada segundo, el **Director** recibe créditos según el tiempo y la profundidad, y los gasta en enemigos de la tabla del reino (cada enemigo tiene un coste).
- Combina **eventos programados** (la línea de tiempo de §6.4) con **ajuste dinámico**: si el jugador mata muy rápido, sube la densidad (más XP). Nunca se castiga ir demasiado bien; la fantasía de poder manda.
- Los enemigos aparecen fuera de cámara, en anillo y evitando obstáculos.
- **Límite de enemigos simultáneos** (600-1.000). Si se alcanza, se fusionan gemas de XP y se pausan los spawns.

---

## 9. Progresión meta

- **Esencia:** se gana por tiempo sobrevivido, jefes derrotados y oro convertido.
- **Armería:** mejoras permanentes (vida, daño, imán, recambios, destierros, revivir…) con coste creciente y opción de reembolso.
- **Desbloqueos por logros** (gran motor de retención): "Evoluciona la Campana" → nueva arma en el pool; "Derrota a La Madre Raíz con Nyra" → aspecto; "Sobrevive 5 min sin moverte" → reliquia nueva…
- **Maestría por campeón** (§4.5).
- **Códice** (§6.1).
- **Cosméticos:** aspectos de campeón (baratos de producir con texturas alternativas).
- **Regla:** la meta-progresión ayuda, pero nunca es obligatoria para ver el final.

---

## 10. Combate: reglas y estadísticas

### 10.1 Estadísticas
Vida · Regeneración · Armadura · Velocidad · Daño % · Área · Duración · Velocidad de proyectil · Cantidad · Presteza (enfriamiento) · Crítico (probabilidad y daño) · Suerte · Imán · Sabiduría (XP) · Codicia · Maldición · Revivir · Recambios / Saltos / Destierros.

- **Fórmula de stats:** `final = (base + Σ planos) × (1 + Σ % aditivos) × Π multiplicadores`
- **Armadura** con rendimiento decreciente: `daño recibido = daño × 100 / (100 + armadura)`.

### 10.2 Estados
Quemadura · Veneno (acumulable) · Ralentización · Congelación · Aturdimiento · Marca (+daño recibido) · Mojado · Electrocutado.
- En los jefes, los controles se reducen en duración, pero no se anulan.
- Números de daño opcionales y agrupados (para no saturar la pantalla).

### 10.3 Muerte y resumen
- Revivir solo mediante reliquias o mejoras.
- **Pantalla de resumen** al morir o ganar: daño por arma, DPS, aumentos elegidos y causa de la muerte. Imprescindible para el jugador y para el balance.

---

## 11. Cámara, controles y UX

- **Cámara:** fija, estilo MOBA (perspectiva con FOV estrecho e inclinación de ~55°), sin rotación. Se aleja ligeramente al subir de nivel y al aparecer el jefe.
- **Controles** (todos reasignables):

| Acción | Teclado y ratón | Mando |
|--------|----------------|-------|
| Moverse | WASD | Stick izquierdo |
| Apuntar | Ratón | Stick derecho / autoapuntado |
| Técnica | Clic derecho / Q | RB |
| Definitiva | R | RT |
| Paso | Espacio | A |
| Pausa / build | Esc / Tab | Start / Select |

- **HUD:** vida y XP, huecos de armas y reliquias, temporizador, muertes, oro, iconos de Técnica/Definitiva con su carga, sinergias activas e indicadores de objetivos fuera de pantalla.
- **Pantalla de subida de nivel:** 3 cartas con icono, nivel y números claros; resalta si una opción completa una evolución o una sinergia.
- **Legibilidad:** contorno del jugador visible a través de todo, opacidad de los efectos propios regulable, telegrafías siempre por encima de los efectos visuales y un código de color fijo (§12).
- **Accesibilidad:** autolanzamiento, desactivar vibración de pantalla, modos para daltonismo, tamaño de interfaz, pausa en cualquier momento y modo asistido (velocidad reducida).

---

## 12. Dirección de arte y audio

- **Estilo:** estilizado, colores saturados, proporciones heroicas y siluetas exageradas. Pintado a mano en campeones y jefes; low-poly con atlas de color en enemigos y escenarios (ver [TECNICO.md](TECNICO.md#5-pipeline-de-arte-blender--godot)).
- **Cada reino:** paleta propia y facción con siluetas reconocibles.
- **Código de color de gameplay (reservado):**
  - 🔴 Rojo/naranja: peligro enemigo (telegrafías)
  - 🔵 Azul/blanco: el jugador y sus efectos
  - 🟡 Dorado: recompensas
  - 🟣 Morado: caos y portales
- **Audio:** respuesta muy marcada (impactos, recogida de XP con tono ascendente en cadena). Música por reino con **capas dinámicas** que suben con la horda y cambian con cada fase del jefe.

---

## 13. Ideas futuras (backlog)

- **Co-op** 2-4 jugadores, local u online (se decide antes de la Fase 2 porque afecta a la arquitectura; ver [ROADMAP](ROADMAP.md#decisiones)).
- Desafío diario o semanal con semilla y tabla de puntuaciones.
- Modo Infinito por reino.
- Reacciones elementales y fusiones de armas.
- Mascotas o compañeros.
- Campeones con transformación (dos formas).
- Hub 3D con NPCs y narrativa entre runs.
- Eventos de temporada.
- Soporte de mods / Steam Workshop (el diseño basado en datos lo facilita).
- Logros de Steam, compatibilidad con Steam Deck y localización.
