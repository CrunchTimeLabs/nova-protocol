extends SceneTree
## Ejecutor de pruebas: descubre todos los `test_*.gd` bajo tests/ (la carpeta refleja la de godot4/) y los corre.
##   godot --headless --import                              (una vez, para registrar las clases)
##   godot --headless -s tests/run_all.gd                   (todo)
##   godot --headless -s tests/run_all.gd -- tests/game     (una carpeta)
##   godot --headless -s tests/run_all.gd -- tests/game/ship/test_ship.gd   (un archivo)
## Sale con código 0 si todo pasa y 1 si algo falla o si no encontró ninguna prueba.


const TESTS_ROOT := "res://tests"
const FILE_PREFIX := "test_"
const FILE_SUFFIX := ".gd"


func _init() -> void:
    var files: Array[String] = []
    _collect(_target_path(), files)
    files.sort()
    var failed_files: int = 0
    var total_tests: int = 0
    var total_checks: int = 0
    for path: String in files:
        var test: BaseTest = _instantiate(path)
        if test == null:
            failed_files += 1
            continue
        test.run_all()
        total_tests += test.tests_run
        total_checks += test.checks
        var label: String = path.trim_prefix(TESTS_ROOT + "/")
        if test.failures.is_empty():
            print("OK     %s (%d pruebas, %d comprobaciones)" % [label, test.tests_run, test.checks])
            continue
        failed_files += 1
        print("FALLO  %s" % label)
        for failure: String in test.failures:
            printerr("       " + failure)
    if files.is_empty():
        printerr("FALLO: no se encontró ninguna prueba en " + _target_path())
        quit(1)
        return
    print("%d archivos, %d pruebas, %d comprobaciones, %d archivos con fallos" % [files.size(), total_tests, total_checks, failed_files])
    quit(1 if failed_files > 0 else 0)


## Carpeta o archivo pedido tras `--`; por defecto, todo tests/.
func _target_path() -> String:
    var args: PackedStringArray = OS.get_cmdline_user_args()
    if args.is_empty():
        return TESTS_ROOT
    var requested: String = args[0]
    return requested if requested.begins_with("res://") else "res://" + requested.trim_prefix("./")


func _collect(path: String, found: Array[String]) -> void:
    if path.ends_with(FILE_SUFFIX):
        found.append(path)
        return
    var dir: DirAccess = DirAccess.open(path)
    if dir == null:
        printerr("FALLO: no se puede abrir " + path)
        return
    for entry: String in dir.get_directories():
        _collect(path.path_join(entry), found)
    for entry: String in dir.get_files():
        if entry.begins_with(FILE_PREFIX) and entry.ends_with(FILE_SUFFIX):
            found.append(path.path_join(entry))


func _instantiate(path: String) -> BaseTest:
    var script: GDScript = load(path) as GDScript
    if script == null:
        printerr("FALLO  %s: no se pudo cargar el script" % path)
        return null
    var test: BaseTest = script.new() as BaseTest
    if test == null:
        printerr("FALLO  %s: debe extender BaseTest" % path)
    return test
