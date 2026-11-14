extends BaseTest
## Capa 1: un comando de la red solo se acepta con la forma exacta; cualquier otra cosa se rechaza.


func test_survives_codec_round_trip() -> void:
    var command: Command = Command.new(2, 1, {"x": 0.5, "y": -1.0})
    var decoded: Dictionary = MessageCodec.decode(MessageCodec.encode(command.to_dict()))
    var back: Command = Command.from_dict(decoded)
    check(back != null, "el comando vuelve a construirse")
    check_equal(back.slot, 2, "slot")
    check_equal(back.kind, 1, "kind")
    check_equal(back.payload, {"x": 0.5, "y": -1.0}, "payload")


func test_invalid_shapes_are_rejected() -> void:
    var invalid: Array[Dictionary] = [
        {},
        {"slot": 0, "kind": 0},
        {"slot": "a", "kind": 0, "payload": {}},
        {"slot": 0, "kind": null, "payload": {}},
        {"slot": 0, "kind": 0, "payload": [1]},
        {"slot": NAN, "kind": 0, "payload": {}},
        {"slot": 0, "kind": INF, "payload": {}},
    ]
    for saved: Dictionary in invalid:
        check(Command.from_dict(saved) == null, "se rechaza %s" % str(saved))
