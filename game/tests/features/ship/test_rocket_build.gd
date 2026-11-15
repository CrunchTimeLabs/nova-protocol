extends BaseTest
## Capa 3 (entidad): se pueden armar las 48 combinaciones de los assets, cada pieza va a su sección y
## el código coincide con el nombre de los PNG de `cohetes_completos`.


func test_all_48_combinations_can_be_built_and_are_different() -> void:
    var combos: Array[Array] = RocketBuild.all_combinations()
    check_equal(combos.size(), 48, "2 × 2 × 2 × 2 × 3")
    var codes: Dictionary = {}
    for combo: Array in combos:
        var build: RocketBuild = RocketBuild.new()
        for part: int in combo:
            build.place(part as RocketParts.Part)
        check(build.is_complete(), "completo")
        codes[build.code()] = true
    check_equal(codes.size(), 48, "todas distintas")
    check(codes.has("C2_A1_T2_P1_M3"), "mismo formato que cohete_C2_A1_T2_P1_M3.png")


func test_each_part_goes_to_its_section_and_replaces() -> void:
    var build: RocketBuild = RocketBuild.new()
    check_equal(build.place(RocketParts.Part.M2), -1, "hueco vacío")
    check_equal(build.part_at(RocketParts.Section.PROPULSION), RocketParts.Part.M2, "a propulsión")
    check_equal(build.place(RocketParts.Part.M3), RocketParts.Part.M2, "sustituye y devuelve la anterior")
    check_equal(build.part_at(RocketParts.Section.PAYLOAD), -1, "las demás siguen vacías")
    check_equal(build.code(), "", "incompleto: sin código")
    check_equal(build.remove(RocketParts.Section.PROPULSION), RocketParts.Part.M3, "se quita")


func test_stacking_matches_the_assets() -> void:
    # Alturas x1 del LEEME: 44 + 14 + 48 + 16 + 40 con 1 px de solape = 158 (los PNG completos miden 158 × 8).
    check_equal(RocketParts.total_height(), 158, "alto del cohete apilado")
    for part: int in RocketParts.CODES.keys():
        var path: String = RocketParts.texture_path(part as RocketParts.Part)
        check(ResourceLoader.exists(path), "existe %s" % path)
        var texture: Texture2D = load(path) as Texture2D
        if texture != null:
            var section: RocketParts.Section = RocketParts.section_of(part as RocketParts.Part)
            check_equal(texture.get_height(), int(RocketParts.SECTION_HEIGHTS[section]), "alto de %s" % path)
            check_equal(texture.get_width(), RocketParts.WIDTH, "ancho de %s" % path)


func test_flame_starts_at_each_engine_nozzle() -> void:
    for part: int in RocketParts.NOZZLE_BOTTOM.keys():
        var texture: Texture2D = load(RocketParts.texture_path(part as RocketParts.Part)) as Texture2D
        var used: Rect2i = texture.get_image().get_used_rect()
        check_equal(used.end.y - 1, int(RocketParts.NOZZLE_BOTTOM[part]), "boquera de %s" % RocketParts.CODES[part])
