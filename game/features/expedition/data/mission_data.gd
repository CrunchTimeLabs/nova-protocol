class_name MissionData
extends RefCounted
## Motores, instrumentos y planetas en bruto (de `mars4/catalogo.py`). `Catalog` los convierte en specs.
## Hallazgos por planeta: [patrón, cantidad medida, nota].


const ENGINES: Array = [
    {"id": "rd1", "threshold": 0, "name": "RD-1 'Chatarra'", "max_mass": 110, "thrust": 1.00, "hull": 100,
     "desc": "Cámara remendada con el metal justo. Levanta poco más que a sí misma: un analizador y poco más."},
    {"id": "rd2", "threshold": 70, "name": "RD-2 'Taller'", "max_mass": 180, "thrust": 1.15, "hull": 115,
     "desc": "Tobera fundida con material decente. Dos analizadores y algo de apoyo, o uno y una nave que aguante."},
    {"id": "rd3", "threshold": 150, "name": "RD-3 'Fundición'", "max_mass": 265, "thrust": 1.32, "hull": 130,
     "desc": "Aleación limpia y refrigeración regenerativa. Ya se puede planificar una campaña científica de verdad."},
    {"id": "rd4", "threshold": 240, "name": "RD-4 'Siderurgia'", "max_mass": 355, "thrust": 1.50, "hull": 150,
     "desc": "Producción industrial. Aun así no entra todo: el catálogo completo pesa más que cualquier motor."},
]

const SUPPORT: Array = [
    {"id": "taladro", "name": "Taladro de regolito", "mass": 40,
     "desc": "Saca muestra del subsuelo en vez de polvo superficial. +3 análisis con CADA analizador que lleves. Con cinco aparatos a bordo son quince medidas más por planeta."},
    {"id": "filtro", "name": "Filtro de correlación", "mass": 12,
     "desc": "Recorta el ruido y descarta dos ventanas falsas en CADA comparación, sea del instrumento que sea."},
    {"id": "computadora", "name": "Computadora de alineación", "mass": 14,
     "desc": "Numera el eje y marca con trazos blancos dónde deberían caer los picos del patrón. Convierte el 'a ojo' en una medida."},
    {"id": "antena", "name": "Antena de alta ganancia", "mass": 20,
     "desc": "Descarga el informe científico completo de cada hallazgo en vez del resumen de dos líneas."},
]

const SHIP: Array = [
    {"id": "blindaje", "name": "Blindaje antirradiación", "mass": 45,
     "desc": "Polietileno borado. Reduce a la mitad el daño de los frentes de radiación solar."},
    {"id": "casco", "name": "Repuesto de casco", "mass": 28,
     "desc": "Placas de sacrificio y espuma estructural. +35 de integridad máxima."},
    {"id": "celdas", "name": "Celdas de fase extra", "mass": 22,
     "desc": "+60 de carga de fase. La barra NO se recarga durante el tramo, así que cada punto es un instante más de intangibilidad."},
    {"id": "panel", "name": "Regulador de flujo de fase", "mass": 16,
     "desc": "Baja el gasto de fase de 34 a 24 por segundo: casi un 30 % más de tiempo intangible con la misma barra."},
    {"id": "deposito", "name": "Depósito auxiliar", "mass": 30,
     "desc": "OBLIGATORIO para el salto al segundo planeta."},
    {"id": "bodega", "name": "Bodega de muestras", "mass": 25,
     "desc": "Duplica lo que recoges de cada orbe durante los tramos de vuelo."},
    {"id": "iman", "name": "Colector electrostático", "mass": 19,
     "desc": "Atrae los orbes de recurso en un radio de 75 px."},
]

const PLANETS: Array = [
    {"id": "luna", "name": "LA LUNA", "subtitle": "Regolito de mares y tierras altas",
     "color": [176, 176, 184], "dark": [98, 98, 106],
     "travel": 68, "density": 1.00, "radiation": 1.00, "fuel": 0,
     "summary": "Sin atmósfera ni campo magnético. Todo lo que trae el viento solar se queda implantado en el polvo y todo lo que cae del espacio llega entero.",
     "findings": {
        "espectroscopio": [
            ["O", "43.0 %", "En óxidos y silicatos, nunca libre."],
            ["Si", "21.0 %", "Base de piroxenos y plagioclasas."],
            ["Fe", "10.5 %", "Hasta 14 % en los mares basálticos."],
            ["Ca", "8.5 %", "Dominante en las tierras altas."],
            ["Al", "7.0 %", "Anortositas del terreno antiguo."],
            ["Mg", "5.5 %", "Olivino y piroxeno magnésico."],
            ["Ti", "1.2 %", "Hasta 5.8 % en Mare Tranquillitatis."],
            ["He", "4 ppb", "Implantado por el viento solar durante 4000 millones de años."],
            ["H2O", "hasta 5 %", "Solo en cráteres polares en sombra permanente."],
        ],
        "difractometro": [
            ["anortita", "~60 % tierras altas", "La roca que define la corteza primitiva."],
            ["augita", "~25 % en los mares", "Piroxeno de los basaltos mare."],
            ["olivino", "~10 %", "Intacto: aquí nunca hubo agua."],
            ["ilmenita", "hasta 20 % en Tranquillitatis", "El recurso minero más valioso de la Luna."],
            ["aglutinado", "20-30 % del suelo", "Vidrio soldado por micrometeoritos."],
        ],
        "cromatografo": [
            ["he4", "~40 000 átomos/cm3", "Exosfera dominada por gases nobles del viento solar."],
            ["ne", "~80 000 átomos/cm3", "El más abundante de la exosfera lunar."],
            ["ar40", "~40 000 átomos/cm3", "Escapa del interior por las grietas."],
            ["h2", "trazas", "Implantado en el regolito, se libera al calentarlo."],
        ],
        "dosimetro": [
            ["k40", "~0.1 % de K en KREEP", "Reloj natural de la corteza lunar."],
            ["th232", "hasta 12 ppm en Procellarum", "Marca el terreno KREEP, el último fundido."],
            ["cosmicos", "~380 microSv/día", "Sin atmósfera ni campo magnético que los frene."],
        ],
        "radiometro": [
            ["regolito_fino", "la mayor parte del suelo", "De 390 K a 100 K en un solo día lunar."],
            ["mare_basaltico", "~17 % de la superficie", "Las llanuras oscuras visibles desde la Tierra."],
            ["sombra_permanente", "~13 000 km2 en los polos", "La trampa fría que conserva el hielo."],
        ],
     }},
    {"id": "marte", "name": "MARTE", "subtitle": "Regolito global y sedimentos de cráter",
     "color": [198, 78, 42], "dark": [120, 42, 22],
     "travel": 86, "density": 1.30, "radiation": 1.35, "fuel": 55,
     "summary": "Atmósfera de CO2 al 95 % con menos del 1 % de la presión terrestre. El regolito está oxidado hasta el fondo y cargado de sales solubles.",
     "findings": {
        "espectroscopio": [
            ["O", "42.0 %", "Sobre todo en SiO2 y óxidos de hierro."],
            ["Si", "20.9 %", "SiO2 cerca del 45 % en masa."],
            ["Fe", "13.6 %", "FeO del 18 %: el más alto del sistema solar interior. Es lo que da el color."],
            ["Mg", "5.0 %", "MgO del 8 %, en olivino."],
            ["Al", "4.8 %", "Al2O3 en torno al 9 %."],
            ["Ca", "4.4 %", "CaO del 6 %, en piroxeno cálcico."],
            ["S", "2.6 %", "Diez veces más que cualquier suelo terrestre normal."],
            ["Cl", "0.5 %", "Percloratos: tóxicos y muy solubles."],
            ["K", "0.36 %", "Marcador de diferenciación de la corteza."],
            ["Ni", "0.05 %", "Contaminación meteorítica del regolito."],
            ["Au", "2 ppb", "Trazas en meteoritos SNC. Cero valor económico."],
            ["H2O", "2 a 10 %", "Hielo a pocos centímetros en latitudes medias."],
            ["CO2s", "casquete", "Hielo seco estacional en el polo sur."],
        ],
        "difractometro": [
            ["hematita", "~5 % del polvo global", "El óxido que pinta el planeta de rojo."],
            ["olivino", "~15 % en terrenos antiguos", "Intacto en zonas que llevan secas eones."],
            ["augita", "~20 %", "Piroxeno de los basaltos marcianos."],
            ["plagio_na", "~30 %", "Plagioclasa más sódica que la lunar."],
            ["jarosita", "local, en Meridiani", "Primera prueba mineral de agua ácida en Marte."],
            ["yeso", "vetas en Endeavour", "Evaporita: aquí se secó una salmuera."],
            ["perclorato", "0.5-1 % del suelo", "Permite salmueras líquidas hoy mismo."],
            ["magnetita", "~2 % del polvo", "Portadora del magnetismo remanente."],
        ],
        "cromatografo": [
            ["co2", "95.3 % de la atmósfera", "Congela y sublima con las estaciones."],
            ["n2", "2.7 %", "Imprescindible para cualquier cultivo."],
            ["ar40", "1.6 %", "Enriquecido por la pérdida de atmósfera."],
            ["o2", "0.13 %", "Con una variación estacional sin explicar."],
            ["co", "0.08 %", "De la fotodisociación del CO2."],
            ["h2o_v", "0.03 % variable", "Poquísima, pero suficiente para escarcha matinal."],
            ["ch4", "0.4 ppb intermitente", "Origen geoquímico o biológico: sin zanjar."],
        ],
        "dosimetro": [
            ["k40", "0.36 % de K", "Coherente con la corteza basáltica."],
            ["th232", "~0.7 ppm", "Medido por el espectrómetro gamma de Mars Odyssey."],
            ["u238", "~0.2 ppm", "Mapea las zonas de corteza evolucionada."],
            ["cosmicos", "~230 microSv/día", "La fina atmósfera apenas frena nada."],
        ],
        "radiometro": [
            ["duna_arena", "campos ecuatoriales", "Arena basáltica movida por el viento."],
            ["roca_expuesta", "paredes de cráter", "Roca compacta sin polvo encima."],
            ["hielo_subsuperficial", "latitudes medias", "Curva demasiado plana para ser otra cosa que hielo."],
            ["costra_sal", "cuencas secas", "Suelo cementado por sulfatos."],
            ["regolito_fino", "Tharsis y Arabia", "Polvo de varios metros de espesor."],
        ],
     }},
]
