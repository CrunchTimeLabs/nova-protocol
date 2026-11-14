extends BaseTest
## El flag de modo: pantalla dividida por defecto; LAN solo si se pide.


func test_default_is_split_screen() -> void:
    check_equal(SessionOptions.from_args(PackedStringArray()).mode, SessionOptions.Mode.SPLIT_SCREEN, "sin flags")
    check_equal(SessionOptions.from_args(PackedStringArray(["--otra-cosa", "--port=abc"])).mode, SessionOptions.Mode.SPLIT_SCREEN, "flags ajenos o inválidos no cambian el modo")


func test_lan_flags() -> void:
    var host: SessionOptions = SessionOptions.from_args(PackedStringArray(["--lan"]))
    check(host.mode == SessionOptions.Mode.LAN and host.is_host, "--lan hospeda")
    var guest: SessionOptions = SessionOptions.from_args(PackedStringArray(["--lan=192.168.1.5", "--port=5000"]))
    check(guest.mode == SessionOptions.Mode.LAN and not guest.is_host, "--lan=IP se une")
    check_equal(guest.address, "192.168.1.5", "dirección")
    check_equal(guest.port, 5000, "puerto")
    var back: SessionOptions = SessionOptions.from_args(PackedStringArray(["--lan", "--split-screen"]))
    check_equal(back.mode, SessionOptions.Mode.SPLIT_SCREEN, "el último flag gana")
