extends BaseTest
## Capa 3 (entidad): se pueden armar las 324 combinaciones de los assets (3·3·3·3·4), cada pieza va a su sección y
## el código coincide con el nombre de los PNG de `cohetes_completos`.


func test_all_combinations_can_be_built_and_are_different() -> void:
    var combos: Array[Array] = RocketBuild.all_combinations()
    check_equal(combos.size(), 324, "3 × 3 × 3 × 3 × 4")
    var codes: Dictionary = {}
    for combo: Array in combos:
        var build: RocketBuild = RocketBuild.new()
        for part: int in combo:
            build.place(part as RocketParts.Part)
        check(build.is_complete(), "completo")
        codes[build.code()] = true
    check_equal(codes.size(), 324, "todas distintas")
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



func test_base_parts_are_weak_and_upgrades_raise_aspects() -> void:
    var base: RocketBuild = RocketBuild.new()
    for part: RocketParts.Part in RocketParts.BASE_PARTS:
        base.place(part)
    var best: RocketBuild = RocketBuild.new()
    for part: RocketParts.Part in [RocketParts.Part.C2, RocketParts.Part.A3, RocketParts.Part.T3, RocketParts.Part.P3, RocketParts.Part.M4]:
        best.place(part)
    for stat: RocketParts.Stat in RocketParts.stats():
        check(base.stat(stat) <= 30, "%s base: %d (débil)" % [RocketParts.STAT_TITLES[stat], base.stat(stat)])
        check(best.stat(stat) > base.stat(stat) + 30, "%s mejora mucho con piezas avanzadas" % RocketParts.STAT_TITLES[stat])
        check(best.stat(stat) <= 100, "nunca pasa de 100")
    check_equal(RocketParts.BASE_PARTS.size() + RocketParts.UNLOCK_ORDER.size(), RocketParts.Part.size(), "cada pieza es base o desbloqueable")


func test_new_parts_have_textures_and_stack_heights() -> void:
    for part: RocketParts.Part in [RocketParts.Part.C3, RocketParts.Part.A3, RocketParts.Part.T3, RocketParts.Part.P3, RocketParts.Part.M4]:
        var texture: Texture2D = load(RocketParts.texture_path(part)) as Texture2D
        check(texture != null, "%s tiene imagen" % RocketParts.CODES[part])
        check_equal(texture.get_height(), int(RocketParts.SECTION_HEIGHTS[RocketParts.section_of(part)]), "%s mide lo de su sección" % RocketParts.CODES[part])
