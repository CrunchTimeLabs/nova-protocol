class_name SessionOptions
extends RefCounted
## Cómo se juega una misión: en una sola pantalla dividida (por defecto) o en red local (LAN).
## Se lee de los argumentos de línea de comandos tras `--` (`godot ... -- --lan`):
##   (sin flag)      pantalla dividida
##   --split-screen  pantalla dividida (explícito)
##   --lan           LAN como anfitrión (el anfitrión también juega)
##   --lan=IP        LAN como jugador que se une a la IP del anfitrión
##   --port=N        puerto (por defecto EnetTransport.DEFAULT_PORT)
## Si un flag se repite, gana el último.


enum Mode { SPLIT_SCREEN, LAN }

const FLAG_SPLIT: String = "--split-screen"
const FLAG_LAN: String = "--lan"
const FLAG_PORT_PREFIX: String = "--port="
const FLAG_LAN_PREFIX: String = "--lan="
const LOOPBACK: String = "127.0.0.1"

var mode: Mode = Mode.SPLIT_SCREEN
## Solo en LAN: true si esta máquina hospeda la partida.
var is_host: bool = true
## Solo en LAN: a dónde conectarse (el anfitrión se conecta a sí mismo por loopback).
var address: String = LOOPBACK
var port: int = EnetTransport.DEFAULT_PORT


static func from_args(args: PackedStringArray) -> SessionOptions:
    var options: SessionOptions = SessionOptions.new()
    for arg: String in args:
        if arg == FLAG_SPLIT:
            options.mode = Mode.SPLIT_SCREEN
        elif arg == FLAG_LAN:
            options.mode = Mode.LAN
            options.is_host = true
            options.address = LOOPBACK
        elif arg.begins_with(FLAG_LAN_PREFIX):
            var host_address: String = arg.trim_prefix(FLAG_LAN_PREFIX)
            if not host_address.is_empty():
                options.mode = Mode.LAN
                options.is_host = false
                options.address = host_address
        elif arg.begins_with(FLAG_PORT_PREFIX):
            var parsed_port: int = arg.trim_prefix(FLAG_PORT_PREFIX).to_int()
            if parsed_port > 0 and parsed_port <= 65535:
                options.port = parsed_port
    return options
