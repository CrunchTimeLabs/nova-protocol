class_name BaseTest
extends RefCounted
## Base de todo archivo de pruebas. Cada método `test_*` es una prueba; `before_each()` se llama antes de cada una.
## Un archivo `tests/<ruta>/test_<clase>.gd` prueba la clase `<ruta>/<clase>.gd` (misma ruta que en godot4/).
## Un fallo no detiene la prueba: se acumula en `failures` con el nombre de la prueba.


const TEST_PREFIX := "test_"

var tests_run: int = 0
var checks: int = 0
var failures: Array[String] = []

var _current_test: String = ""


## Estado limpio para cada prueba: sobrescribir y crear aquí lo que las pruebas comparten.
func before_each() -> void:
    pass


func run_all() -> void:
    var names: Array[String] = []
    for method: Dictionary in get_method_list():
        var method_name: String = String(method["name"])
        if method_name.begins_with(TEST_PREFIX):
            names.append(method_name)
    names.sort()
    for method_name: String in names:
        _current_test = method_name
        before_each()
        call(method_name)
        tests_run += 1


func check(condition: bool, message: String) -> void:
    checks += 1
    if not condition:
        failures.append("%s: %s" % [_current_test, message])


func check_equal(actual: Variant, expected: Variant, message: String) -> void:
    check(actual == expected, "%s (obtenido %s, esperado %s)" % [message, str(actual), str(expected)])


func check_approx(actual: float, expected: float, message: String) -> void:
    check(is_equal_approx(actual, expected), "%s (obtenido %s, esperado %s)" % [message, str(actual), str(expected)])
