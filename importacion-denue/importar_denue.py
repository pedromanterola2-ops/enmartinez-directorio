#!/usr/bin/env python3
"""
EnMartinez — Importador de negocios desde el DENUE (INEGI)

Toma el CSV del DENUE de Veracruz, se queda con Martínez de la Torre y
produce un SQL listo para pegar en Supabase (SQL Editor), más un CSV para
revisar a ojo.

Uso:
  python3 importar_denue.py denue_inegi_30_.csv negocios_actuales.json salida/
     [--sin-telefono] [--todas-localidades] [--origen denue-2026-05]

- negocios_actuales.json: lo que ya hay en la tabla (GET /rest/v1/negocios),
  para no duplicar.
- Por defecto solo toma negocios CON teléfono de la cabecera municipal.
"""
import csv, json, math, re, sys, unicodedata, difflib, argparse, os

# ─────────────────────────── Categorías ───────────────────────────
CAT_LABELS = {
  'restaurantes':'🍽️ Restaurantes', 'abarrotes':'🛒 Abarrotes', 'salud':'🏥 Salud',
  'talleres':'🔧 Talleres', 'belleza':'💇 Belleza', 'hoteles':'🏨 Hoteles',
  'construccion':'🏗️ Construcción', 'veterinarias':'🐾 Veterinarias y mascotas', 'ropa':'👗 Ropa',
  'servicios':'⚡ Servicios Profesionales', 'agro':'🌿 Agro', 'educacion':'🏫 Educación',
  'tecnologia':'💻 Tecnología', 'eventos':'🎉 Eventos', 'transporte':'🚕 Transporte',
  'panaderias':'🥐 Panaderías', 'cafes':'☕ Cafés y cafeterías', 'botanas':'🥤 Botanas y bebidas',
  'comida':'🍱 Comida', 'bancos':'🏦 Bancos', 'profesionales':'⚖️ Profesionales',
  'agroindustria':'🍊 Agroindustria', 'oficios':'🔩 Oficios y servicios del hogar',
  'papelerias':'📚 Papelerías y regalos',
}
CAT_ICONS = {
  'restaurantes':'🍽️','abarrotes':'🛒','salud':'💊','talleres':'🔧','belleza':'💇','hoteles':'🏨',
  'construccion':'🏗️','veterinarias':'🐾','ropa':'👗','servicios':'⚡','agro':'🌿','educacion':'🏫',
  'tecnologia':'💻','eventos':'🎉','transporte':'🚕','panaderias':'🥐','cafes':'☕','botanas':'🥤',
  'comida':'🍱','bancos':'🏦','profesionales':'⚖️','agroindustria':'🍊','oficios':'🔩','papelerias':'📚',
}

# Código SCIAN (prefijo más largo gana) → (categoría, frase para la descripción)
# Frase = qué es el negocio, en lenguaje de cliente. None = usar la de INEGI.
SCIAN = {
  # Abarrotes y alimentos al menudeo
  '461110': ('abarrotes', 'Tienda de abarrotes'),
  '461121': ('abarrotes', 'Carnicería'),
  '461122': ('abarrotes', 'Pollería'),
  '461123': ('abarrotes', 'Pescadería'),
  '461130': ('abarrotes', 'Venta de frutas y verduras'),
  '461140': ('abarrotes', 'Venta de semillas y granos'),
  '461150': ('abarrotes', 'Venta de lácteos y embutidos'),
  '461160': ('abarrotes', 'Dulcería y venta de materias primas para repostería'),
  '461170': ('botanas', 'Paletería y nevería'),
  '461190': ('abarrotes', 'Venta de alimentos'),
  '461211': ('botanas', 'Venta de vinos y licores'),
  '461212': ('botanas', 'Depósito de cerveza'),
  '461213': ('botanas', 'Venta de bebidas y hielo'),
  '462112': ('abarrotes', 'Minisúper'),
  '4311':   ('abarrotes', 'Venta de abarrotes al mayoreo'),
  '3115':   ('abarrotes', 'Elaboración de lácteos'),
  '3116':   ('abarrotes', 'Venta de carnes y embutidos'),
  '3121':   ('botanas', 'Purificadora de agua'),
  '311910': ('botanas', 'Elaboración de botanas'),
  '311923': ('cafes', 'Tostado y venta de café'),
  # Panaderías y tortillerías
  '3118':   ('panaderias', 'Panadería'),
  '311830': ('comida', 'Tortillería'),
  '311820': ('panaderias', 'Elaboración de galletas y pastas'),
  '311340': ('panaderias', 'Dulces y repostería'),
  # Restaurantes / comida / cafés
  '722511': ('restaurantes', 'Restaurante de comida corrida y a la carta'),
  '722512': ('restaurantes', 'Restaurante de pescados y mariscos'),
  '722513': ('restaurantes', 'Antojitos'),
  '722514': ('restaurantes', 'Tacos y tortas'),
  '722516': ('restaurantes', 'Restaurante'),
  '611691': ('educacion', 'Clases particulares'),
  '465213': ('talleres', 'Venta de bicicletas'),
  '466319': ('oficios', 'Artículos de decoración para el hogar'),
  '463214': ('ropa', 'Vestidos de novia, disfraces y ropa regional'),
  '314991': ('ropa', 'Bordados y confección textil'),
  '332310': ('oficios', 'Estructuras metálicas'),
  '339950': ('servicios', 'Rotulación y anuncios'),
  '722517': ('comida', 'Pizzas, hamburguesas, hot dogs o pollos para llevar'),
  '722518': ('comida', 'Comida para llevar'),
  '722519': ('comida', 'Preparación de alimentos'),
  '722515': ('cafes', 'Cafetería'),
  '722412': ('botanas', 'Bar'),
  '722411': ('botanas', 'Centro nocturno'),
  '7223':   ('comida', 'Servicio de comida para eventos'),
  # Hoteles
  '721111': ('hoteles', 'Hotel'),
  '721112': ('hoteles', 'Hotel'),
  '721190': ('hoteles', 'Hospedaje'),
  '721311': ('hoteles', 'Casa de huéspedes'),
  '721312': ('hoteles', 'Departamentos amueblados'),
  # Belleza
  '812110': ('belleza', 'Estética y salón de belleza'),
  '812120': ('belleza', 'Baños y sanitarios'),
  '465111': ('belleza', 'Venta de perfumería y cosméticos'),
  '713943': ('salud', 'Gimnasio'),
  # Salud
  '6211':   ('salud', 'Consultorio médico'),
  '621111': ('salud', 'Consultorio de medicina general'),
  '621113': ('salud', 'Consultorio de medicina especializada'),
  '621115': ('salud', 'Clínica'),
  '621211': ('salud', 'Consultorio dental'),
  '621311': ('salud', 'Consultorio de quiropráctica'),
  '621320': ('salud', 'Consultorio de optometría'),
  '621331': ('salud', 'Consultorio de psicología'),
  '621341': ('salud', 'Terapia física, ocupacional o de lenguaje'),
  '621391': ('salud', 'Consultorio de nutrición'),
  '621398': ('salud', 'Consultorio de salud'),
  '621411': ('salud', 'Centro de planificación familiar'),
  '621511': ('salud', 'Laboratorio de análisis clínicos'),
  '621512': ('salud', 'Centro de imagenología'),
  '621610': ('salud', 'Enfermería a domicilio'),
  '621910': ('salud', 'Servicio de ambulancias'),
  '622111': ('salud', 'Hospital'),
  '464111': ('salud', 'Farmacia'),
  '464112': ('salud', 'Farmacia con minisúper'),
  '464113': ('salud', 'Tienda naturista'),
  '464121': ('salud', 'Óptica'),
  '464122': ('salud', 'Venta de artículos ortopédicos'),
  # Talleres automotrices
  '811111': ('talleres', 'Taller mecánico'),
  '811112': ('talleres', 'Taller eléctrico automotriz'),
  '811113': ('talleres', 'Rectificadora de motores'),
  '811114': ('talleres', 'Taller de transmisiones'),
  '811115': ('talleres', 'Taller de suspensiones'),
  '811116': ('talleres', 'Alineación y balanceo'),
  '811119': ('talleres', 'Taller mecánico'),
  '811121': ('talleres', 'Hojalatería y pintura'),
  '811122': ('talleres', 'Tapicería automotriz'),
  '811129': ('talleres', 'Reparación de carrocerías'),
  '811191': ('talleres', 'Vulcanizadora'),
  '811192': ('talleres', 'Autolavado'),
  '811199': ('talleres', 'Servicio automotriz'),
  '811492': ('talleres', 'Taller de motocicletas'),
  '811493': ('talleres', 'Taller de bicicletas'),
  '8113':   ('talleres', 'Reparación de maquinaria y equipo'),
  '468211': ('talleres', 'Refaccionaria'),
  '468212': ('talleres', 'Venta de refacciones usadas'),
  '468213': ('talleres', 'Llantera'),
  '468311': ('talleres', 'Venta de motocicletas y refacciones'),
  # Transporte
  '468111': ('transporte', 'Venta de autos nuevos'),
  '468112': ('transporte', 'Compra y venta de autos usados'),
  '485':    ('transporte', 'Servicio de transporte de pasajeros'),
  '484':    ('transporte', 'Fletes y mudanzas'),
  '4921':   ('transporte', 'Paquetería y mensajería'),
  '488':    ('transporte', 'Servicios para el transporte'),
  '532110': ('transporte', 'Renta de autos'),
  # Oficios y hogar
  '332320': ('oficios', 'Herrería'),
  '3371':   ('oficios', 'Fabricación de muebles'),
  '321910': ('oficios', 'Carpintería'),
  '321920': ('oficios', 'Fabricación de productos de madera'),
  '811211': ('tecnologia', 'Reparación de electrónicos'),
  '811219': ('tecnologia', 'Reparación de equipo electrónico'),
  '811410': ('oficios', 'Reparación de aparatos eléctricos y electrodomésticos'),
  '811420': ('oficios', 'Tapicería de muebles'),
  '811430': ('oficios', 'Reparación de calzado'),
  '811491': ('oficios', 'Cerrajería'),
  '811499': ('oficios', 'Reparación de artículos para el hogar'),
  '812210': ('oficios', 'Lavandería y tintorería'),
  '2382':   ('oficios', 'Instalaciones eléctricas, de plomería o aire acondicionado'),
  '2383':   ('oficios', 'Acabados para la construcción'),
  '561710': ('oficios', 'Fumigación y control de plagas'),
  '561720': ('oficios', 'Servicio de limpieza'),
  '466111': ('oficios', 'Mueblería'),
  '466112': ('oficios', 'Venta de electrodomésticos'),
  '466113': ('oficios', 'Venta de artículos para el hogar'),
  '466114': ('oficios', 'Venta de cristalería y artículos para cocina'),
  '466312': ('eventos', 'Florería'),
  # Construcción
  '467111': ('construccion', 'Ferretería y tlapalería'),
  '467112': ('construccion', 'Venta de pisos y recubrimientos'),
  '467113': ('construccion', 'Venta de pintura'),
  '467114': ('construccion', 'Vidrios y espejos'),
  '467115': ('oficios', 'Venta de artículos de limpieza'),
  '4344':   ('construccion', 'Materiales para construcción'),
  '434211': ('construccion', 'Materiales para construcción'),
  '434219': ('construccion', 'Materiales para construcción'),
  '434224': ('construccion', 'Venta de madera'),
  '434225': ('construccion', 'Venta de material eléctrico'),
  '434227': ('construccion', 'Materiales para construcción'),
  '434228': ('construccion', 'Materiales para construcción'),
  '3273':   ('construccion', 'Fabricación de block y materiales'),
  '3274':   ('construccion', 'Fabricación de materiales para construcción'),
  '3279':   ('construccion', 'Fabricación de materiales para construcción'),
  '236':    ('construccion', 'Construcción'),
  '237':    ('construccion', 'Obra civil'),
  # Ropa
  '4631':   ('ropa', 'Venta de telas y mercería'),
  '463211': ('ropa', 'Tienda de ropa'),
  '463212': ('ropa', 'Ropa de bebé'),
  '463213': ('ropa', 'Lencería'),
  '463215': ('ropa', 'Bisutería y accesorios'),
  '463216': ('ropa', 'Ropa de trabajo y uniformes'),
  '463217': ('ropa', 'Pañalera'),
  '463218': ('ropa', 'Sombreros'),
  '463310': ('ropa', 'Zapatería'),
  '466410': ('ropa', 'Venta de artículos usados'),
  '465211': ('ropa', 'Joyería y relojería'),
  '3152':   ('ropa', 'Confección de ropa'),
  '3159':   ('ropa', 'Confección de accesorios'),
  '812990': ('servicios', 'Servicios personales'),
  # Papelerías
  '465311': ('papelerias', 'Papelería'),
  '465312': ('papelerias', 'Librería'),
  '465313': ('papelerias', 'Venta de revistas y periódicos'),
  '465912': ('papelerias', 'Tienda de regalos'),
  '465914': ('papelerias', 'Venta de artículos religiosos'),
  '465915': ('papelerias', 'Venta de artículos desechables'),
  '465919': ('papelerias', 'Venta de artículos varios'),
  '465212': ('papelerias', 'Juguetería'),
  '465215': ('papelerias', 'Venta de artículos deportivos'),
  '323':    ('papelerias', 'Imprenta'),
  '561431': ('papelerias', 'Copias e impresiones'),
  # Mascotas
  '465911': ('veterinarias', 'Tienda de mascotas'),
  '541941': ('veterinarias', 'Veterinaria'),
  '541942': ('agro', 'Veterinaria para ganado'),
  '434311': ('agro', 'Venta de alimento para animales'),
  # Tecnología
  '466211': ('tecnologia', 'Venta de computadoras y accesorios'),
  '466212': ('tecnologia', 'Venta y reparación de celulares'),
  '466213': ('tecnologia', 'Venta de electrónicos'),
  '561432': ('tecnologia', 'Cibercafé'),
  '5415':   ('tecnologia', 'Servicios de cómputo y sistemas'),
  # Eventos
  '531113': ('eventos', 'Salón de fiestas'),
  '532282': ('eventos', 'Renta de mobiliario para fiestas'),
  '541920': ('eventos', 'Fotografía y video'),
  '711':    ('eventos', 'Espectáculos y entretenimiento'),
  '7139':   ('eventos', 'Centro recreativo'),
  '713120': ('eventos', 'Juegos y entretenimiento'),
  '713998': ('eventos', 'Centro recreativo'),
  # Agro y agroindustria
  '434111': ('agro', 'Venta de fertilizantes, plaguicidas y semillas'),
  '434112': ('agro', 'Venta de medicamentos veterinarios y alimento para animales'),
  '435110': ('agro', 'Venta de maquinaria agrícola'),
  '1151':   ('agroindustria', 'Servicios agrícolas'),
  '115113': ('agroindustria', 'Empaque y beneficio de productos agrícolas'),
  '431130': ('agroindustria', 'Compra y venta de frutas al mayoreo'),
  '3114':   ('agroindustria', 'Procesamiento de frutas'),
  '493':    ('agroindustria', 'Almacenamiento y refrigeración'),
  # Profesionales y servicios
  '541110': ('profesionales', 'Despacho jurídico'),
  '541120': ('profesionales', 'Notaría'),
  '541190': ('profesionales', 'Servicios legales'),
  '541211': ('profesionales', 'Despacho contable'),
  '541219': ('profesionales', 'Servicios de contabilidad'),
  '5413':   ('profesionales', 'Arquitectura e ingeniería'),
  '5414':   ('profesionales', 'Diseño'),
  '5416':   ('profesionales', 'Consultoría'),
  '5418':   ('servicios', 'Publicidad'),
  '5312':   ('servicios', 'Inmobiliaria'),
  '5242':   ('servicios', 'Agencia de seguros'),
  '812310': ('servicios', 'Funeraria'),
  '561510': ('servicios', 'Agencia de viajes'),
  '5616':   ('servicios', 'Seguridad privada'),
  '532':    ('servicios', 'Renta de equipo'),
  # Bancos / financieras locales
  '5221':   ('bancos', 'Banco'),
  '5222':   ('bancos', 'Caja de ahorro'),
  '5223':   ('bancos', 'Servicios financieros'),
  '5224':   ('bancos', 'Casa de empeño o préstamos'),
  '5225':   ('bancos', 'Servicios financieros'),
}

# Educación privada: por texto ("sector privado")
EDU_FRASES = [
  ('preescolar', 'Escuela preescolar'), ('primaria', 'Escuela primaria'),
  ('secundaria', 'Escuela secundaria'), ('media superior', 'Bachillerato'),
  ('superior', 'Universidad'), ('idiomas', 'Escuela de idiomas'),
  ('deporte', 'Escuela de deportes'), ('arte', 'Escuela de arte'),
  ('profesores particulares', 'Clases particulares'), ('computación', 'Escuela de computación'),
  ('guarderías', 'Guardería'),
]

# Cadenas y empresas grandes: el directorio es de negocios locales
CADENAS = re.compile(r"""\b(OXXO|COPPEL|ELEKTRA|AURRERA|WAL ?MART|SORIANA|CHEDRAUI|SUPER CHE|
  FARMACIAS? GUADALAJARA|FARMACIAS? (DEL|DE) AHORRO|SIMILARES|SAN PABLO|BENAVIDES|YZA|
  BBVA|BANCOMER|SANTANDER|BANAMEX|CITIBANAMEX|BANORTE|HSBC|SCOTIABANK|BANCO AZTECA|BANCOPPEL|
  BANJERCITO|BANSEFI|BANCO DEL BIENESTAR|COMPARTAMOS|FAMSA|AFIRME|INBURSA|BANREGIO|BANBAJIO|
  TELCEL|TELMEX|MOVISTAR|AT ?& ?T|IUSACELL|TOTALPLAY|IZZI|MEGACABLE|PEMEX|OXXO GAS|
  DOMINO|LITTLE CAESAR|KFC|BURGER KING|MC ?DONALD|STARBUCKS|SUBWAY|CARLS JR|
  TIENDAS? 3B|TIENDAS? NETO|SEVEN ELEVEN|7 ?ELEVEN|CIRCULO K|MODELORAMA|SIX|
  AUTOZONE|STEREN|PRICE SHOES|CKLASS|SUBURBIA|WOOLWORTH|ESTAFETA|DHL|FEDEX|REDPACK|
  WESTERN UNION|ELEKTRA|COMEX|SHERWIN|LICONSA|DICONSA|IMSS|ISSSTE|CFE|DIF|SAT|
  CRUZ ROJA|PREPA ABIERTA|CONALEP|CECYTEV|TELEBACHILLERATO|AXA|GNP|METLIFE|
  FINANCIERA INDEPENDENCIA|CREDITO FAMSA|MONTE DE PIEDAD|PRENDAMEX|FIRST CASH|
  CINEPOLIS|COCA ?COLA|PEPSI|BIMBO|SABRITAS|LALA|ALPURA|BACHOCO|CORONA DISTRIBUIDORA|
  FARMACIAS? ISSSTE|TOTAL ?GAS|GAS NATURAL|HIDROGAS|GLOBAL GAS|ZETA GAS)\b""", re.X)

# Palabras genéricas: si el nombre solo tiene esto, no es un nombre (no se publica)
GENERICAS = set("""
SIN NOMBRE NOMBRE TIENDA TIENDITA ABARROTES ABARROTE MISCELANEA MISCELANIA DE DEL LA LAS LOS EL Y E EN CON PARA
ESTETICA ESTETICAS SALON BELLEZA PELUQUERIA BARBERIA TALLER MECANICO MECANICA AUTOMOTRIZ ELECTRICO HERRERIA
CARPINTERIA RESTAURANTE RESTAURANT FONDA COCINA ECONOMICA TAQUERIA TACOS TORTAS ANTOJITOS COMIDA COMIDAS
CORRIDA PAPELERIA FARMACIA CONSULTORIO MEDICO DENTAL DENTISTA CLINICA CARNICERIA POLLERIA FRUTERIA VERDULERIA
TORTILLERIA PANADERIA PAN REFACCIONARIA VULCANIZADORA LLANTERA ZAPATERIA ROPA BOUTIQUE FERRETERIA TLAPALERIA
LAVANDERIA CIBER CIBERCAFE VENTA COMPRA REPARACION SERVICIO SERVICIOS PURIFICADORA AGUA EXPENDIO DEPOSITO
CERVEZA BAR CANTINA CAFETERIA CAFE NEVERIA PALETERIA JUGOS LICUADOS REGALOS NOVEDADES COCTELERIA MARISCOS
POLLOS ASADOS ROSTIZADOS PIZZERIA PIZZAS HAMBURGUESAS HOT DOGS DOGOS LOCAL PUESTO NEGOCIO COMERCIO COMERCIAL
MATERIALES CONSTRUCCION FUNERARIA HOTEL POSADA GIMNASIO GYM VETERINARIA FLORERIA MERCERIA OPTICA LABORATORIO
CELULARES ACCESORIOS DESPACHO CONTABLE JURIDICO NOTARIA ESCUELA COLEGIO GUARDERIA BLOCK BLOQUERA
AUTOLAVADO LAVADO AUTOS MOTOS BICICLETAS DULCERIA DULCES SEMILLAS CREMERIA PESCADERIA FORRAJERA
AGROQUIMICOS FERTILIZANTES DISTRIBUIDORA EMPACADORA PLATANOS LIMON LIMONES CITRICOS ALIMENTOS PRODUCTOS
""".split())

# El INEGI captura todo en mayúsculas y casi siempre sin acentos.
# Solo se corrigen palabras inequívocas (nunca nombres propios dudosos).
ACENTOS = {w.upper().translate(str.maketrans('ÁÉÍÓÚÜ', 'AEIOUU')): w for w in """
Martínez López Juárez Domínguez Rodríguez Hernández Sánchez Gutiérrez Pérez Suárez Gómez Ramírez González
Fernández Jiménez Vázquez Velázquez Álvarez Méndez Díaz Ruíz Núñez Ordóñez Benítez Chávez Márquez Valdés Ortíz
José María Jesús Ángel Ávila Lázaro Cárdenas Héroes Alemán Cuauhtémoc Moctezuma Paraíso México Constitución
Revolución República Unión Ampliación Educación Nutrición Reparación Elaboración Construcción Instalación
Computación Supervisión Fumigación Decoración Impresión Comunicación Producción Distribución Atención
Taquería Estética Mecánico Mecánica Carnicería Papelería Tortillería Carpintería Hojalatería Herrería
Panadería Lavandería Económica Zapatería Médico Médica Médicos Peluquería Pollería Barbería Clínica Clínicas
Clínicos Eléctrico Eléctrica Eléctricos Electrónica Electrónicos Cervecería Jurídico Jurídicos Rosticería
Balconería Florería Público Públicos Pública Óptica Cafetería Ferretería Pescadería Pastelería Pastelerías
Verdulería Frutería Mercería Tapicería Joyería Relojería Librería Mueblería Cerrajería Dulcería Cremería
Nevería Paletería Coctelería Marisquería Juguetería Perfumería Refaccionaría Vidriería Lonchería Juguería
Tlapalería Cocina Artículos Análisis Diagnóstico Odontología Psicología Fisioterapia Pediatría Ginecología
Rápida Rápido Técnico Técnica Plásticos Lácteos Químicos Agrícola Agrícolas Ecológico Mágico
Mágica Jardín Galería Música Fotografía Diseño Señor Niños Niño Niña Peña Cañizo Hidalgo Belisario Gálvez
Martín Ramón Adrián Simón Germán Julián Iván Rubén Andrés Tomás Nicolás Sebastián Joaquín Agustín Efraín
Raúl Óscar Héctor Víctor Félix Inés Sofía Lucía Rocío Mónica Verónica Angélica Bárbara Débora Jazmín
Belén Concepción Asunción Guía Día Más Café Cafés Mamá Papá Abarrotería Ciber Fénix Edén Edén Limón
Agroquímicos Cosméticos Metálicas Metálicos Regularización Aplicación Salón Magón Rayón Ibáñez
Asesoría Gestoría Electrodomésticos Automóviles Óptico Pizzería Química Químico Teléfono Teléfonos
Vía Ávalos Ríos Río Montaña Época Única Único Clásico Clásica Auténtico Auténtica Típico Típica Tradición
""".split()}
ACENTOS.pop('COCINA', None); ACENTOS.pop('HIDALGO', None); ACENTOS.pop('BELISARIO', None)
ACENTOS.pop('CIBER', None); ACENTOS.pop('MOCTEZUMA', None)

MINUSCULAS = {'de','del','la','las','los','el','y','e','en','con','para','a','al','por','o','u','sin'}
SIGLAS = {'SA','CV','SC','DE','RL','II','III','IV','MX','TV','DJ','SPR','MC'}

def sin_acentos(s):
    return ''.join(c for c in unicodedata.normalize('NFD', s) if unicodedata.category(c) != 'Mn')

def norm(s):
    s = sin_acentos(str(s or '')).upper()
    s = re.sub(r'[^A-Z0-9 ]', ' ', s)
    return re.sub(r'\s+', ' ', s).strip()

def titulo(s):
    """'TIENDA DE ABARROTES DON CHOFO' → 'Tienda de Abarrotes Don Chofo'"""
    s = re.sub(r'\s+', ' ', str(s or '').strip())
    out = []
    for i, w in enumerate(s.split(' ')):
        lw = w.lower()
        clave = sin_acentos(w).upper()
        if clave in ACENTOS and not (i > 0 and lw in MINUSCULAS):
            out.append(ACENTOS[clave])
        elif i > 0 and lw in MINUSCULAS:
            out.append(lw)
        elif re.fullmatch(r'[IVX]+', w) and len(w) <= 4:
            out.append(w)
        elif '"' in w or '“' in w:
            out.append(w[:2].upper() + w[2:].lower() if w[0] in '"“' else w.capitalize())
        else:
            out.append(lw[:1].upper() + lw[1:])
    return ' '.join(out)

def es_generico(nombre):
    if 'SIN NOMBRE' in norm(nombre):
        return True
    toks = [t for t in norm(nombre).split() if t not in GENERICAS and not t.isdigit()]
    return len(toks) == 0

def categoria(codigo, nombre_act, nombre):
    if 'sector público' in nombre_act or 'sector publico' in nombre_act:
        return None
    if codigo.startswith('61') and 'privado' in nombre_act:
        for k, f in EDU_FRASES:
            if k in nombre_act.lower():
                return ('educacion', f)
        return ('educacion', 'Escuela')
    for n in range(6, 2, -1):
        if codigo[:n] in SCIAN:
            cat, frase = SCIAN[codigo[:n]]
            # Neverías / juguerías vienen revueltas con cafeterías
            if codigo == '722515' and re.search(r'NEVER|PALET|REFRESQ|JUGO|LICUAD|AGUAS|RASPA|HELAD|SNACK|ESQUIT|ELOTE', norm(nombre)):
                return ('botanas', 'Nevería, jugos y snacks')
            return (cat, frase)
    return None

def tel10(t):
    d = re.sub(r'\D', '', str(t or ''))
    if d.startswith('52') and len(d) == 12: d = d[2:]
    if d.startswith('521') and len(d) == 13: d = d[3:]
    return d if len(d) == 10 else None

VIAL = {'AVENIDA':'Av.', 'BOULEVARD':'Blvd.', 'CALZADA':'Calz.', 'CARRETERA':'Carr.',
        'PROLONGACION':'Prol.', 'ANDADOR':'And.', 'PRIVADA':'Priv.', 'CERRADA':'Cda.',
        'CALLEJON':'Callejón', 'CAMINO':'Camino', 'PERIFERICO':'Periférico', 'CIRCUITO':'Circuito',
        'RETORNO':'Retorno', 'AMPLIACION':'Ampl.', 'BRECHA':'Brecha', 'VEREDA':'Vereda', 'PASAJE':'Pasaje'}
ASENT = {'COLONIA':'Col.', 'FRACCIONAMIENTO':'Fracc.', 'BARRIO':'Barrio', 'UNIDAD HABITACIONAL':'U.H.',
         'CONJUNTO HABITACIONAL':'Conj. Hab.', 'EJIDO':'Ejido', 'AMPLIACION':'Ampl.',
         'ZONA INDUSTRIAL':'Zona Ind.', 'CONDOMINIO':'Cond.', 'RESIDENCIAL':'Resid.'}
VACIO = {'', 'NAN', 'NINGUNO', 'NINGUNA', 'SIN NOMBRE', 'SIN NUMERO', '0', 'S/N', 'NO APLICA'}

def v(x):
    x = str(x or '').strip()
    return '' if x.upper() in VACIO else x

def calle_txt(tipo, nombre):
    nombre = v(nombre)
    if not nombre: return ''
    pref = VIAL.get(str(tipo).strip().upper(), '')
    return (pref + ' ' if pref else '') + titulo(nombre)

def colonia_txt(r):
    asent = v(r['nomb_asent'])
    if not asent: return ''
    if norm(asent) == 'CENTRO': return 'Centro'
    pref = ASENT.get(str(r['tipo_asent']).strip().upper(), 'Col.')
    return f'{pref} {titulo(asent)}'

def direccion(r):
    calle = calle_txt(r['tipo_vial'], r['nom_vial'])
    num = v(r['numero_ext'])
    if num and v(r['letra_ext']): num += v(r['letra_ext'])
    partes = []
    if calle:
        partes.append(f'{calle} {num}' if num else f'{calle} s/n')
    e1, e2 = calle_txt(r['tipo_v_e_1'], r['nom_v_e_1']), calle_txt(r['tipo_v_e_2'], r['nom_v_e_2'])
    if partes and not num and e1 and e2:
        partes[-1] += f' (entre {e1} y {e2})'
    if v(r['nom_CenCom']):
        partes.append(titulo(r['nom_CenCom']) + (f' local {v(r["num_local"])}' if v(r['num_local']) else ''))
    col = colonia_txt(r)
    if col: partes.append(col)
    cp = v(r['cod_postal'])
    loc = titulo(r['localidad']) if r['localidad'] else 'Martínez de la Torre'
    partes.append(f'{cp + " " if cp else ""}{loc}, Ver.')
    return ', '.join(partes)

def descripcion(frase, r):
    col = v(r['nomb_asent'])
    loc = titulo(r['localidad'])
    if col and norm(col) == 'CENTRO':
        donde = f'en el centro de {loc}'
    elif col:
        donde = f'en {colonia_txt(r).replace("Col. ", "la colonia ").replace("Fracc. ", "el fraccionamiento ")}, {loc}'
    else:
        donde = f'en {loc}'
    return f'{frase} {donde}.'

def dist_m(a, b, c, d):
    try:
        a, b, c, d = map(float, (a, b, c, d))
    except (TypeError, ValueError):
        return 1e9
    R = 6371000
    p1, p2 = math.radians(a), math.radians(c)
    dp, dl = p2 - p1, math.radians(d - b)
    h = math.sin(dp/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return 2*R*math.asin(math.sqrt(h))

def sql_txt(x):
    if x is None or x == '': return 'null'
    return "'" + str(x).replace("'", "''") + "'"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('denue_csv'); ap.add_argument('actuales_json'); ap.add_argument('salida')
    ap.add_argument('--sin-telefono', action='store_true', help='incluir también los que no tienen teléfono')
    ap.add_argument('--todas-localidades', action='store_true', help='incluir Independencia, María de la Torre, etc.')
    ap.add_argument('--origen', default='denue-2026-05')
    a = ap.parse_args()
    os.makedirs(a.salida, exist_ok=True)

    actuales = json.load(open(a.actuales_json, encoding='utf-8'))
    stats = {}
    def cuenta(k): stats[k] = stats.get(k, 0) + 1

    filas = []
    with open(a.denue_csv, encoding='latin-1', newline='') as f:
        for r in csv.DictReader(f):
            if 'Martínez de la Torre' not in (r.get('municipio') or ''): continue
            cuenta('total municipio')
            if not a.todas_localidades and r['localidad'].strip() != 'Martínez de la Torre':
                cuenta('fuera de la cabecera'); continue
            nombre = v(r['nom_estab'])
            if not nombre or es_generico(nombre):
                cuenta('sin nombre propio'); continue
            if CADENAS.search(norm(nombre)) or CADENAS.search(norm(r['raz_social'])):
                cuenta('cadena o empresa grande'); continue
            if r['per_ocu'] in ('51 a 100 personas', '101 a 250 personas', '251 y más personas'):
                cuenta('más de 50 empleados'); continue
            cat = categoria(r['codigo_act'], r['nombre_act'], nombre)
            if not cat:
                cuenta('giro fuera del directorio (gobierno, religión, etc.)'); continue
            tel = tel10(r['telefono'])
            if not tel and not a.sin_telefono:
                cuenta('sin teléfono'); continue
            filas.append((r, nombre, cat, tel))

    # Duplicados dentro del DENUE (mismo nombre y teléfono)
    vistos, unicos = set(), []
    for x in filas:
        k = (norm(x[1]), x[3])
        if k in vistos: cuenta('duplicado dentro del DENUE'); continue
        vistos.add(k); unicos.append(x)

    # Duplicados contra lo que ya está en EnMartinez
    def ya_existe(r, nombre, tel):
        nn = norm(nombre)
        for n in actuales:
            na = norm(n['nombre'])
            t = tel10(n.get('telefono'))
            if tel and t and tel == t: return n['nombre']
            ratio = difflib.SequenceMatcher(None, nn, na).ratio()
            if ratio > 0.85: return n['nombre']
            # nombre del actual contenido en el del DENUE y cerca
            core = [w for w in na.split() if w not in GENERICAS and len(w) > 3]
            if core and all(w in nn for w in core) and dist_m(r['latitud'], r['longitud'], n.get('lat'), n.get('lng')) < 300:
                return n['nombre']
        return None

    finales, dups = [], []
    for r, nombre, cat, tel in unicos:
        e = ya_existe(r, nombre, tel)
        if e: dups.append((nombre, e)); cuenta('ya está en EnMartinez'); continue
        finales.append((r, nombre, cat, tel))

    # ── Salidas ──
    regs = []
    for r, nombre, (cat, frase), tel in finales:
        web, fb = '', ''
        w = v(r['www']).lower()
        if w:
            if not w.startswith('http'): w = 'https://' + w
            if 'facebook' in w: fb = w
            else: web = w
        regs.append({
            'nombre': titulo(nombre), 'categoria': cat, 'cat_label': CAT_LABELS[cat], 'icono': CAT_ICONS[cat],
            'descripcion': descripcion(frase, r), 'direccion': direccion(r), 'telefono': tel or '',
            'whatsapp': '', 'horario': '', 'facebook': fb, 'web': web,
            'lat': float(r['latitud']), 'lng': float(r['longitud']),
            'modalidad': 'local', 'origen': a.origen, 'denue_clee': r['clee'],
            'giro_inegi': r['nombre_act'], 'personal': r['per_ocu'], 'alta_inegi': r['fecha_alta'],
        })
    regs.sort(key=lambda x: (x['categoria'], x['nombre']))

    with open(os.path.join(a.salida, 'negocios-denue-revision.csv'), 'w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(regs[0].keys()))
        w.writeheader(); w.writerows(regs)

    with open(os.path.join(a.salida, 'negocios-denue.sql'), 'w', encoding='utf-8') as f:
        f.write(f"""-- ═══════════════════════════════════════════════════════════════════
--  EnMartinez — Carga de {len(regs)} negocios del DENUE (INEGI)
--  Fuente: Directorio Estadístico Nacional de Unidades Económicas,
--          actualización mayo 2026. Solo cabecera municipal, con teléfono,
--          sin cadenas, sin gobierno y sin nombres genéricos.
--
--  CÓMO USARLO:
--    Supabase → proyecto LaPastora → SQL Editor → New query
--    → pegar TODO este archivo → Run.
--  Se puede correr más de una vez: no duplica (usa denue_clee).
--
--  PARA DESHACERLO COMPLETO:
--    delete from public.negocios where origen = '{a.origen}';
--  Los negocios que captures a mano quedan con origen = null y no se tocan.
-- ═══════════════════════════════════════════════════════════════════

alter table public.negocios add column if not exists origen text;
alter table public.negocios add column if not exists denue_clee text;
create unique index if not exists negocios_denue_clee_uniq
  on public.negocios (denue_clee) where denue_clee is not null;
notify pgrst, 'reload schema';

insert into public.negocios
  (nombre, categoria, cat_label, icono, descripcion, direccion, telefono, whatsapp, horario,
   servicios, pago, facebook, web, destacado, lat, lng, modalidad, origen, denue_clee)
values
""")
        vals = []
        for x in regs:
            vals.append('(' + ', '.join([
                sql_txt(x['nombre']), sql_txt(x['categoria']), sql_txt(x['cat_label']), sql_txt(x['icono']),
                sql_txt(x['descripcion']), sql_txt(x['direccion']), sql_txt(x['telefono']), 'null', 'null',
                "'[]'::jsonb", "'[]'::jsonb", sql_txt(x['facebook']) if x['facebook'] else "''",
                sql_txt(x['web']) if x['web'] else "''", 'false',
                f"{x['lat']:.6f}", f"{x['lng']:.6f}", "'local'", sql_txt(x['origen']), sql_txt(x['denue_clee']),
            ]) + ')')
        f.write(',\n'.join(vals))
        f.write("""
on conflict (denue_clee) where denue_clee is not null do nothing;

-- Verificación
select categoria, count(*) from public.negocios group by categoria order by 2 desc;
""")

    resumen = {'filtros': stats, 'cargables': len(regs),
               'por_categoria': {}, 'duplicados_con_enmartinez': dups}
    for x in regs: resumen['por_categoria'][x['categoria']] = resumen['por_categoria'].get(x['categoria'], 0) + 1
    json.dump(resumen, open(os.path.join(a.salida, 'resumen.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(resumen, ensure_ascii=False, indent=1))

if __name__ == '__main__':
    main()
