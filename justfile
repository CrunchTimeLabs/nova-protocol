# Nova Protocol: tareas del proyecto. Uso: `just` lista las recetas.
# Las variables se leen de `.env` (local, ignorado por git; plantilla en `.env.example`):
#   ITCH_USER  usuario de itch.io        ITCH_GAME  nombre del juego en su URL        GODOT  ruta de Godot (opcional)

set dotenv-load

godot := env("GODOT", home_directory() / "bin/godot")
itch_user := env("ITCH_USER")
itch_game := env("ITCH_GAME")
itch_channel := "web"
web_dir := "build/web"

# Lista las recetas.
default:
    @just --list

# Importa los recursos del proyecto (una vez, o tras añadir archivos).
import:
    cd game && {{godot}} --headless --import

# Ejecuta todas las pruebas del dominio y el toolkit.
test: import
    cd game && {{godot}} --headless -s tests/run_all.gd

# Exporta la versión web (preset "Web" de game/export_presets.cfg) a game/build/web/.
build-web: import
    rm -rf game/{{web_dir}}
    mkdir -p game/{{web_dir}}
    cd game && {{godot}} --headless --export-release "Web" {{web_dir}}/index.html

# Inicia sesión en itch.io (una sola vez).
login:
    butler login

# Pruebas, exportación web y subida a itch.io con butler (<usuario>/<juego>:web).
deploy-web: test build-web
    butler push game/{{web_dir}} {{itch_user}}/{{itch_game}}:{{itch_channel}} --userversion "$(git rev-parse --short HEAD)$(git diff --quiet HEAD || echo -dirty)"

# Borra lo exportado.
clean:
    rm -rf game/build
