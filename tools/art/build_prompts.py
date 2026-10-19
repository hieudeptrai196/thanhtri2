"""Builds the THÀNH TRÌ prompt pack for a text/image-to-3D AI: docs/ASSET_PROMPTS.md + an HTML page."""
import html
import sys

STYLE = ("Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures "
         "with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, "
         "clean readable silhouette, game-ready, single object, no base, plain background.")
NEGATIVE = ("realistic, photorealistic, Chinese dragon, Japanese torii, samurai armor, tiny noisy details, thin fragile "
            "parts, text, logo, ground base, pedestal, multiple objects, blurry texture")
CHAR = " Heroic chibi proportions about 3.5 heads tall, A-pose, full body, front view."
MAX = 600  # common prompt limit of text-to-3D tools

# (code, file, name_vi, wave, triangles, notes_vi, subject)
ASSETS = [
    ("Nhân vật — 5 class (mỗi class 1 model riêng)", [
        ("CH-03", "ch03_general", "Võ tướng — làm đầu tiên, dùng làm mẫu phong cách", 1, "8.000",
         "A-pose. Auto-rig humanoid. Màu nhận diện: đỏ.",
         "Vietnamese general warrior, Ly-Tran dynasty lamellar armor with bronze plates and red cloth, red headscarf "
         "under a bronze helmet with short plume, broad shoulders, big curved saber in right hand." + CHAR),
        ("CH-01", "ch01_engineer", "Công binh", 2, "8.000",
         "A-pose. Màu nhận diện: cam đồng.",
         "Vietnamese army engineer, copper-orange tunic and headband, leather tool belt with nails and measuring rope, "
         "oversized wooden mallet in right hand, small bundle of planks on the back." + CHAR),
        ("CH-02", "ch02_woodcutter", "Tiều phu", 2, "8.000",
         "A-pose. Màu nhận diện: xanh lá. Gùi to = túi đồ gấp đôi.",
         "Vietnamese woodcutter, green and brown peasant clothes, green bandana, sturdy legs with leg wraps, "
         "big axe in right hand, large woven bamboo basket backpack." + CHAR),
        ("CH-04", "ch04_shaman", "Thầy pháp", 2, "8.000",
         "A-pose. Màu nhận diện: tím.",
         "Vietnamese folk shaman, purple robe with yellow paper talismans, tall cloth hat, wooden staff with small "
         "bronze bells and hanging charms in right hand, calm mystical look." + CHAR),
        ("CH-05", "ch05_mechanic", "Thợ máy", 2, "8.000",
         "A-pose. Màu nhận diện: xám thép.",
         "Vietnamese blacksmith mechanic, steel-grey tunic, thick leather apron, bronze goggles on forehead, soot "
         "smudges, big bronze wrench in right hand, small bellows on the back." + CHAR),
    ]),
    ("Quái (truyền thuyết Việt)", [
        ("EN-01", "en01_forest_demon", "Quỷ rừng — quái thường", 1, "2.000",
         "Rất nhiều con cùng lúc → để polycount thấp. Auto-rig humanoid. Mắt phát sáng.",
         "Forest demon from Vietnamese folklore, hunched humanoid made of rotten dark wood and moss, long arms with "
         "claws, glowing yellow eyes, dark red and moss green colors, menacing but cartoony, A-pose, full body."),
        ("EN-02", "en02_will_o_wisp", "Ma trơi — quái nhanh", 3, "1.500",
         "Nhỏ, cao ~1 m.",
         "Will-o'-the-wisp ghost from Vietnamese folklore, small floating blue-green flame spirit with a glowing face "
         "and two tiny clawed arms, wispy flame tail instead of legs, cartoony and creepy."),
        ("EN-03", "en03_ghoul", "Quỷ nhập tràng — quái trâu", 3, "4.000",
         "To, cao ~2.4 m.",
         "Huge bloated undead ghoul from Vietnamese folklore, torn white funeral shroud, grey-green skin, heavy fists, "
         "slow and strong, glowing pale eyes, cartoony, A-pose, full body."),
        ("EN-04a", "en04_fish_demon", "Boss Ngư tinh", 3, "15.000",
         "Boss, cao ~6 m.",
         "Giant fish demon boss from the Lac Long Quan legend, armored scales, huge jaws with fangs, fin claws, walks "
         "on stubby legs, teal and gold colors, glowing eyes, epic and cartoony."),
        ("EN-04b", "en04_fox_demon", "Boss Hồ tinh", 3, "15.000",
         "Boss, cao ~5 m.",
         "Giant nine-tailed fox demon boss from Vietnamese legend, white and crimson fur, nine flaming tails, sly face "
         "with glowing eyes, bronze ornaments, standing on four legs, epic and cartoony."),
        ("EN-04c", "en04_tree_demon", "Boss Mộc tinh", 3, "15.000",
         "Boss, cao ~7 m.",
         "Giant ancient tree demon boss from Vietnamese legend, banyan tree body with hanging aerial roots as beard, "
         "angry carved face, root legs and branch arms, moss and glowing amber eyes, epic and cartoony."),
    ]),
    ("Pháo đài — tòa thành chạy bánh xe (thân và bánh xe tạo riêng, Claude lắp)", [
        ("FT-01", "ft01_fortress_wood", "Thân pháo đài cấp Gỗ (không bánh xe)", 1, "30.000",
         "Footprint vuông, thấp và rộng. Nóc phẳng ở giữa để đặt nỏ. KHÔNG có bánh xe.",
         "Body of a mobile siege citadel without wheels: miniature ancient Vietnamese Co Loa fortress, square low wide "
         "hull of ironwood log palisade walls with sharpened stakes, iron bands and rivets, bronze battering ram at the "
         "front, small gatehouse with upturned curved roof, flags, flat open roof deck in the middle."),
        ("FT-01w", "ft01_wheel", "Bánh xe (dùng 4–6 cái)", 1, "2.000",
         "Một bánh duy nhất, nhìn ngang. Claude nhân bản và quay trong game.",
         "Single giant wooden war wagon wheel, thick chunky spokes, heavy iron rim with rivets, bronze hub cap with a "
         "Dong Son drum star pattern, side view."),
        ("FT-02", "ft02_fortress_stone", "Thân pháo đài cấp Đá (không bánh xe)", 2, "30.000",
         "Cùng hình dáng với FT-01, đổi vật liệu.",
         "Body of a mobile siege citadel without wheels: miniature ancient Vietnamese Co Loa fortress, square low wide "
         "hull of rammed earth and grey stone brick walls with crenellations, thick iron bands, bronze battering ram at "
         "the front, gatehouse with upturned tiled roof, flags, flat open roof deck in the middle."),
        ("FT-03", "ft03_fortress_bronze", "Thân pháo đài cấp Bọc đồng (làm sau)", 3, "30.000",
         "Cùng hình dáng, cấp cao nhất.",
         "Body of a mobile siege citadel without wheels: miniature ancient Vietnamese fortress clad in engraved bronze "
         "plates with Dong Son drum motifs and Lac bird patterns, stone base, golden battering ram, grand gatehouse "
         "with upturned roof, banners, flat open roof deck in the middle."),
    ]),
    ("Module trên pháo đài (tạo riêng, Claude gắn lên thân)", [
        ("FM-01", "fm01_repeating_crossbow", "Nỏ liên châu", 1, "2.500",
         "Nỏ trên nóc thành, xoay theo hướng ngắm. Rộng ~2.2 m.",
         "Large repeating crossbow siege weapon on a rotating wooden turntable base, ironwood frame with bronze fittings, "
         "magazine of arrows on top, hand crank on the back, chunky."),
        ("FM-03", "fm03_ladder", "Thang leo lên nỏ", 1, "500",
         "Cao ~5 m, áp vào tường.",
         "Sturdy wooden siege ladder leaning against a wall, thick bamboo rails lashed with rope, about 5 meters tall."),
        ("FM-04", "fm04_boiling_oil", "Dầu sôi", 2, "1.500",
         "~1.2 m.",
         "Bronze cauldron of boiling oil on a wooden stand with a tilting pouring chute, smoke and bubbling oil, Dong Son "
         "patterns on the cauldron."),
        ("FM-05", "fm05_coal_furnace", "Lò lửa đốt Than", 2, "1.500",
         "~1.2 m, lửa phát sáng.",
         "Small coal furnace of clay bricks with an iron door glowing orange, short chimney with smoke, coal pile beside "
         "it, bronze trim."),
        ("FM-07", "fm07_divine_crossbow", "Nỏ thần (trên vọng lâu phía trước)", 2, "4.000",
         "Chi tiết đẹp nhất trên thành.",
         "Legendary giant magic crossbow of King An Duong Vuong, golden bronze body engraved with Dong Son motifs, "
         "glowing golden turtle-claw trigger, mounted on an ornate wooden stand, majestic."),
        ("FM-08", "fm08_stakes", "Chông gai (đoạn tường chông)", 2, "800",
         "Một đoạn dài ~3 m, Claude lặp quanh chân tường.",
         "Row of sharpened wooden and bamboo stakes tied with rope, 3 meters long strip, angled outward, for the base "
         "of a fortress wall."),
    ]),
    ("Công trình ngoài thực địa", [
        ("ST-01", "st01_turret_base", "Tháp nỏ — phần thân (không có nỏ)", 1, "2.500",
         "Cao ~1.6 m. Phần nỏ dùng chung model ST-01b.",
         "Small wooden watchtower base for a crossbow turret, octagonal log frame with stone footing, iron bands, rope "
         "lashings, flat platform on top (no weapon), about 1.6 meters tall."),
        ("ST-01b", "st01_turret_bow", "Tháp nỏ — đầu nỏ xoay", 1, "1.500",
         "Rộng ~1.4 m, gắn lên ST-01.",
         "Compact mounted crossbow head for a defense turret, ironwood bow with bronze tips, loaded arrow, small "
         "rotating pivot underneath, chunky."),
        ("ST-01f", "st01_turret_folded", "Tháp nỏ — gấp gọn để vác", 2, "1.000",
         "~0.9 × 0.9 × 0.6 m, nhân vật vác trên lưng.",
         "Folded wooden crossbow turret packed into a compact bundle tied with rope and straps, logs and bow parts, "
         "ready to carry on the back."),
        ("ST-02", "st02_barricade", "Rào gỗ", 2, "2.000",
         "3 × 1.4 × 0.8 m.",
         "Wooden spiked barricade, cheval de frise made of sharpened logs and bamboo tied with rope, 3 meters wide, "
         "sturdy and chunky."),
        ("ST-02f", "st02_barricade_folded", "Rào gỗ — gấp gọn để vác", 2, "800",
         "~0.9 × 0.9 × 0.6 m.",
         "Bundle of sharpened logs and bamboo stakes tied tightly with rope, compact, ready to carry on the back."),
        ("ST-X", "st_debris", "Đống đổ nát (công trình bị phá)", 2, "1.000",
         "Dùng chung cho mọi công trình.",
         "Pile of broken wooden planks, splintered logs and torn rope from a destroyed small wooden structure, low "
         "flat pile."),
    ]),
    ("Tài nguyên & thế giới", [
        ("WD-01a", "wd01_tree_a", "Cây A (cho Gỗ)", 1, "1.500",
         "Cao 3–5 m.",
         "Stylized broadleaf tree from a Vietnamese forest, thick twisted trunk, round chunky leaf clusters, lush "
         "green, about 4 meters tall."),
        ("WD-01b", "wd01_tree_b", "Cây B (cho Gỗ)", 1, "1.500",
         "Cao 3–5 m.",
         "Stylized clump of tall green bamboo stalks with leaves, Vietnamese countryside, about 5 meters tall."),
        ("WD-01c", "wd01_tree_c", "Cây C (cho Gỗ)", 2, "1.500",
         "Cao 4–5 m.",
         "Stylized small banyan tree with hanging aerial roots, wide canopy, chunky trunk, Vietnamese village style."),
        ("WD-01s", "wd01_stump", "Gốc cây (khi hết gỗ)", 1, "500",
         "",
         "Chopped tree stump with fresh cut top, roots and a few wood chips, stylized."),
        ("WD-02", "wd02_coal_rock", "Mỏ than", 2, "1.500",
         "~2.2 × 1.6 × 2.2 m.",
         "Limestone rock outcrop with thick shiny black coal veins and a few coal chunks at the base, stylized."),
        ("WD-03a", "wd03_pile_wood", "Đống đồ rơi — Gỗ", 2, "600",
         "~0.7 m.",
         "Small bundle of firewood logs tied with rope, stylized pickup item."),
        ("WD-03b", "wd03_pile_coal", "Đống đồ rơi — Than", 2, "600",
         "~0.7 m.",
         "Small woven basket full of black coal chunks, stylized pickup item."),
        ("WD-03c", "wd03_pile_bronze", "Đống đồ rơi — Đồng", 2, "600",
         "~0.7 m.",
         "Small pile of bronze scraps, bronze arrowheads and a broken bronze plate with Dong Son pattern, shiny, "
         "stylized pickup item."),
        ("WD-04", "wd04_stop_gate", "Mốc điểm dừng (cổng)", 2, "6.000",
         "Rộng ~10 m, pháo đài đi qua.",
         "Ancient Vietnamese three-entrance temple gate (tam quan), wooden pillars, upturned curved tiled roofs, red "
         "and gold, lanterns hanging, about 10 meters wide."),
        ("WD-07a", "wd07_bamboo_fence", "Đạo cụ — hàng rào tre", 2, "500",
         "Dài ~3 m.",
         "Short woven bamboo fence section, Vietnamese village, 3 meters long."),
        ("WD-07b", "wd07_shrine", "Đạo cụ — miếu nhỏ", 2, "1.500",
         "~1.5 m.",
         "Small roadside Vietnamese shrine with upturned tiled roof on a brick base, incense pot, red and moss colors."),
        ("WD-07c", "wd07_jars_sacks", "Đạo cụ — chum và bao tải", 2, "800",
         "",
         "Group of two clay water jars and a rice sack, Vietnamese countryside props."),
        ("WD-07d", "wd07_rocks", "Đạo cụ — đá", 2, "500",
         "",
         "Cluster of three rounded mossy limestone rocks, stylized."),
        ("WD-07e", "wd07_banner", "Đạo cụ — cờ hiệu", 2, "500",
         "",
         "Tall bamboo pole with a triangular red war banner with bronze drum emblem, stylized."),
        ("WD-07f", "wd07_lantern", "Đạo cụ — đèn lồng trên cột", 2, "500",
         "",
         "Wooden post with a hanging red silk lantern, stylized, Vietnamese village."),
    ]),
]

for _, items in ASSETS:
    for code, *_rest, subject in items:
        full = subject + " " + STYLE
        if len(full) > MAX:
            sys.exit(f"{code}: {len(full)} chars > {MAX}")

WAVE = {1: "Đợt 1", 2: "Đợt 2", 3: "Đợt 3"}

GUIDE = [
    ("Cài đặt chung cho mọi asset", [
        "Chế độ **Text to 3D** (hoặc Image to 3D nếu có ảnh mẫu). Nếu có chọn phong cách: chọn **Stylized / Cartoon**, không chọn Realistic.",
        "Bật **texture PBR**. Xuất file **GLB**.",
        "**Số tam giác mục tiêu** (target polycount / remesh): theo cột *Tam giác* của từng asset.",
        "Nếu có ô **Negative prompt**: dán đoạn Negative ở dưới.",
        "Mỗi asset tạo **3–4 bản**, chọn bản **nhìn rõ nhất từ trên cao chéo xuống** (game nhìn nghiêng 35°, nhân vật chỉ cao ~60 px trên màn hình).",
    ]),
    ("Giữ phong cách đồng bộ", [
        "Làm **CH-03 Võ tướng trước**. Khi ưng, chụp ảnh model đó.",
        "Các asset sau: nếu công cụ cho dùng **ảnh tham chiếu phong cách** (style reference / image prompt), đưa ảnh Võ tướng vào cùng với prompt chữ.",
        "Giữ nguyên **đoạn Style** ở cuối mọi prompt (đã gộp sẵn trong từng prompt bên dưới).",
    ]),
    ("Nhân vật và quái: rig + animation", [
        "Dùng tính năng **auto-rig humanoid** của công cụ (nhân vật để A-pose đúng như prompt).",
        "Animation cần lấy từ thư viện của công cụ (nếu có): **idle, run, attack (chém kiếm), hit, death**; có thêm thì lấy: **walk, dash/roll, kneel (quỳ), lie down (gục), cheer/cast (dùng kỹ năng), hammer/chop**.",
        "Tải về **GLB có rig** + từng animation (hoặc một GLB chứa nhiều animation).",
        "Animation nào công cụ không có: Claude tự làm hoặc thay thế trong Godot.",
    ]),
    ("Gửi file cho Claude", [
        "Đặt tên file theo cột *Tên file* (vd `ch03_general.glb`), gửi **xong cái nào gửi cái đó**.",
        "Không cần chỉnh tỉ lệ, gốc tọa độ, hướng mặt, hay lắp ráp: Claude làm hết trong Godot (gắn bánh xe vào thân, nỏ vào tháp, module lên nóc).",
        "Thứ tự nhanh nhất: **FT-01 + FT-01w → CH-03 → EN-01 → ST-01 + ST-01b → WD-01a/b + WD-01s → FM-01, FM-03** (hết đợt 1), rồi các mục đợt 2.",
    ]),
]

NOT_3D = [
    ("Mặt đất, dải đường", "Claude làm bằng shader trong Godot (AI 3D không tạo texture lặp liền được)."),
    ("Hiệu ứng (nổ, chém, khói, khiên, bùa…)", "Claude làm bằng hạt / shader trong Godot."),
    ("Icon tài nguyên, công trình, chân dung class", "Claude chụp từ chính các model 3D ở trên trong Godot → đồng bộ phong cách, không cần AI vẽ riêng."),
    ("Khung thẻ, nút, thanh máu, logo", "Cần AI tạo ảnh 2D (Midjourney, GPT Image…): báo Claude nếu muốn bộ prompt ảnh; nếu không, Claude tiếp tục vẽ bằng code."),
    ("Font chữ tiếng Việt", "Claude chọn font miễn phí bản quyền (giấy phép OFL) — cần bạn cho phép tải."),
    ("Âm thanh", "Claude lo (hệ thống + âm tạm; âm thật từ thư viện CC0 nếu bạn cho phép tải)."),
]


def md() -> str:
    out = ["# THÀNH TRÌ — Bộ prompt cho AI tạo 3D",
           "",
           "> 2026-10-19. Dùng cho AI tạo 3D từ chữ / ảnh (Meshy, Tripo, Rodin…). Mỗi khối **Prompt** dán nguyên vào ô prompt, mỗi lần một asset.",
           "> Bản đầy đủ về phong cách và thông số: [`ASSET_SPEC.md`](ASSET_SPEC.md). Prompt viết tiếng Anh vì các công cụ này hiểu tiếng Anh tốt nhất.",
           ""]
    for title, bullets in GUIDE:
        out += [f"## {title}", ""] + [f"- {b}" for b in bullets] + [""]
    out += ["## Negative prompt (dán vào ô Negative nếu công cụ có)", "", "```", NEGATIVE, "```", ""]
    for group, items in ASSETS:
        out += [f"## {group}", ""]
        for code, file, name, wave, tris, notes, subject in items:
            out += [f"### {code} · {name}", "",
                    f"- Tên file: `{file}.glb` · Tam giác: **{tris}** · {WAVE[wave]}" + (f" · {notes}" if notes else ""),
                    "", "```", subject + " " + STYLE, "```", ""]
    out += ["## Phần không cần AI tạo 3D", "", "| Phần | Ai làm |", "|---|---|"]
    out += [f"| {a} | {b} |" for a, b in NOT_3D]
    return "\n".join(out) + "\n"


def inline(text: str) -> str:
    """**bold** and `code` from the guide strings."""
    t = html.escape(text)
    parts = t.split("**")
    t = "".join(f"<b>{p}</b>" if i % 2 else p for i, p in enumerate(parts))
    parts = t.split("`")
    return "".join(f"<code>{p}</code>" if i % 2 else p for i, p in enumerate(parts))


def page() -> str:
    count = sum(len(items) for _, items in ASSETS)
    wave1 = sum(1 for _, items in ASSETS for a in items if a[3] == 1)
    guide = "".join(
        f'<div class="guide"><h3>{html.escape(t)}</h3><ul>' + "".join(f"<li>{inline(b)}</li>" for b in bs) + "</ul></div>"
        for t, bs in GUIDE)
    groups = []
    for group, items in ASSETS:
        cards = []
        for code, file, name, wave, tris, notes, subject in items:
            pid = "p-" + code.lower()
            cards.append(f'''<article class="card w{wave}" data-wave="{wave}">
  <header><span class="code">{code}</span><h4>{html.escape(name)}</h4><span class="wave">{WAVE[wave]}</span></header>
  <dl><div><dt>Tên file</dt><dd><code>{file}.glb</code></dd></div><div><dt>Tam giác</dt><dd>{tris}</dd></div></dl>
  {f'<p class="note">{html.escape(notes)}</p>' if notes else ''}
  <div class="prompt"><textarea id="{pid}" readonly rows="5">{html.escape(subject + " " + STYLE)}</textarea>
  <button type="button" class="copy" data-target="{pid}">Copy prompt</button></div>
</article>''')
        groups.append(f'<section class="group"><h2>{html.escape(group)}</h2><div class="cards">{"".join(cards)}</div></section>')
    rows = "".join(f"<tr><td>{html.escape(a)}</td><td>{html.escape(b)}</td></tr>" for a, b in NOT_3D)
    return TEMPLATE.format(count=count, wave1=wave1, guide=guide, negative=html.escape(NEGATIVE),
                           groups="".join(groups), rows=rows)


TEMPLATE = """<title>Thành Trì — prompt 3D</title>
<meta name="claude:viewport-fit-sides" content="cover">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+2:wght@600;800&family=Be+Vietnam+Pro:wght@400;500;600;700&family=JetBrains+Mono:wght@500&display=swap">
<style>
/* Layout: guide first, then one card per asset with its prompt ready to copy; filter by wave. Game palette: wood / bronze / parchment. */
:root {{
  --bg: #f6eedb; --surface: #fffaf0; --fg: #2a1d12; --muted: #6e5a45; --line: #e0d0b2;
  --wood: #3d2919; --bronze: #b5741f; --bronze-soft: #f3dfb8; --w1: #a2362b; --w1-soft: #f5d9d4;
  --display: "Baloo 2", "Be Vietnam Pro", system-ui, sans-serif;
  --body: "Be Vietnam Pro", system-ui, -apple-system, "Segoe UI", sans-serif;
  --mono: "JetBrains Mono", ui-monospace, Menlo, Consolas, monospace;
}}
@media (prefers-color-scheme: dark) {{ :root:not([data-theme="light"]) {{
  --bg: #1b130c; --surface: #261b12; --fg: #f5e8cc; --muted: #b9a68a; --line: #3f2f20;
  --wood: #f5e8cc; --bronze: #ffcc6b; --bronze-soft: #3a2a17; --w1: #f0a093; --w1-soft: #3d1f1a; color-scheme: dark }} }}
:root[data-theme="dark"] {{
  --bg: #1b130c; --surface: #261b12; --fg: #f5e8cc; --muted: #b9a68a; --line: #3f2f20;
  --wood: #f5e8cc; --bronze: #ffcc6b; --bronze-soft: #3a2a17; --w1: #f0a093; --w1-soft: #3d1f1a; color-scheme: dark }}
* {{ box-sizing: border-box }}
body {{ background: var(--bg); color: var(--fg); font: 16px/1.6 var(--body);
  padding-left: max(16px, env(safe-area-inset-left, 0px)); padding-right: max(16px, env(safe-area-inset-right, 0px)); padding-block: 0 64px }}
.wrap {{ max-width: 1080px; margin: 0 auto }}
header.top {{ padding-block: 44px 24px; border-bottom: 3px double var(--bronze); display: grid; gap: 10px }}
.eyebrow {{ font: 600 13px/1 var(--body); letter-spacing: .12em; text-transform: uppercase; color: var(--bronze) }}
h1 {{ font: 800 clamp(38px, 7vw, 62px)/1 var(--display); margin: 0; color: var(--wood); text-wrap: balance }}
h1 small {{ display: block; font: 600 clamp(17px, 2.4vw, 22px)/1.35 var(--display); color: var(--muted); margin-top: 6px }}
.lead {{ max-width: 72ch; margin: 0 }}
h2 {{ font: 800 26px/1.2 var(--display); color: var(--wood); margin: 44px 0 14px; text-wrap: balance }}
h3 {{ font: 700 18px/1.3 var(--display); margin: 0 0 6px; color: var(--wood) }}
code {{ font: 500 .86em var(--mono); background: var(--bronze-soft); padding: 1px 5px; border-radius: 4px }}
.guides {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 14px; margin-top: 18px }}
.guide {{ background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 14px 16px; min-width: 0 }}
.guide ul {{ margin: 0; padding-left: 18px; display: grid; gap: 6px; font-size: 14.5px }}
.neg {{ display: grid; gap: 8px; margin-top: 14px; background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 14px 16px }}
.filters {{ position: sticky; top: env(safe-area-inset-top, 0px); z-index: 5; background: var(--bg); display: flex; flex-wrap: wrap; gap: 8px; align-items: center; padding-block: 12px; border-bottom: 1px solid var(--line) }}
body::before {{ content: ""; position: fixed; inset: 0 0 auto; height: env(safe-area-inset-top, 0px); z-index: 10; background: var(--bg) }}
.filters span {{ font-size: 14px; color: var(--muted); margin-right: 4px }}
.filters button, .copy {{ font: 600 14px var(--body); border: 1px solid var(--line); background: var(--surface); color: var(--fg); border-radius: 999px; padding: 6px 14px; cursor: pointer }}
.filters button[aria-pressed="true"] {{ background: var(--wood); color: var(--bg); border-color: var(--wood) }}
.filters button:focus-visible, .copy:focus-visible, textarea:focus-visible {{ outline: 2px solid var(--bronze); outline-offset: 2px }}
.cards {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 14px }}
.card {{ background: var(--surface); border: 1px solid var(--line); border-radius: 8px; padding: 14px 16px; display: grid; gap: 8px; align-content: start; min-width: 0 }}
.card.w1 {{ border-top: 3px solid var(--w1) }}
.card header {{ display: flex; gap: 10px; align-items: baseline; flex-wrap: wrap }}
.card h4 {{ margin: 0; font: 700 16.5px/1.3 var(--body); flex: 1 1 160px; min-width: 0 }}
.card .code {{ font: 500 13px var(--mono); color: var(--bronze) }}
.wave {{ font: 700 11px/1 var(--body); letter-spacing: .06em; text-transform: uppercase; color: var(--muted); border: 1px solid var(--line); border-radius: 4px; padding: 4px 6px }}
.w1 .wave {{ color: var(--w1); border-color: var(--w1); background: var(--w1-soft) }}
dl {{ display: flex; flex-wrap: wrap; gap: 4px 18px; margin: 0; font-size: 14px }}
dl div {{ display: flex; gap: 6px }} dt {{ color: var(--muted) }} dd {{ margin: 0; font-variant-numeric: tabular-nums }}
.note {{ margin: 0; font-size: 14px; color: var(--muted) }}
.prompt {{ display: grid; gap: 8px }}
textarea {{ width: 100%; resize: vertical; font: 500 12.5px/1.5 var(--mono); color: var(--fg); background: var(--bg); border: 1px solid var(--line); border-radius: 6px; padding: 8px 10px }}
.copy {{ justify-self: start; background: var(--bronze-soft); border-color: var(--bronze) }}
.copy.done {{ background: var(--wood); color: var(--bg) }}
.scroll {{ overflow-x: auto; border: 1px solid var(--line); border-radius: 8px; background: var(--surface) }}
table {{ border-collapse: collapse; width: 100%; font-size: 14.5px; min-width: 520px }}
th, td {{ text-align: left; vertical-align: top; padding: 9px 12px; border-bottom: 1px solid var(--line) }}
th {{ font: 600 12px/1.3 var(--body); letter-spacing: .06em; text-transform: uppercase; color: var(--muted); background: var(--bg) }}
tr:last-child td {{ border-bottom: 0 }}
footer {{ margin-top: 48px; padding-top: 14px; border-top: 1px solid var(--line); color: var(--muted); font-size: 13px }}
</style>

<div class="wrap">
<header class="top">
  <div class="eyebrow">Cho AI tạo 3D · Meshy / Tripo / Rodin · 19/10/2026</div>
  <h1>THÀNH TRÌ<small>Bộ prompt tạo asset 3D — {count} asset, {wave1} asset đợt 1</small></h1>
  <p class="lead">Mỗi thẻ là một asset: bấm <b>Copy prompt</b>, dán vào ô prompt của công cụ, đặt số tam giác theo thẻ, tải về file GLB và đặt tên đúng như thẻ. Đoạn phong cách chung đã gộp sẵn ở cuối mọi prompt.</p>
  <div class="guides">{guide}</div>
  <div class="neg"><h3>Negative prompt</h3><p class="note" style="margin:0">Dán vào ô Negative nếu công cụ có.</p>
    <textarea id="p-negative" readonly rows="2">{negative}</textarea>
    <button type="button" class="copy" data-target="p-negative">Copy negative</button></div>
</header>

<nav class="filters" aria-label="Lọc theo đợt"><span>Hiện:</span>
  <button type="button" data-filter="all" aria-pressed="true">Tất cả</button>
  <button type="button" data-filter="1" aria-pressed="false">Đợt 1</button>
  <button type="button" data-filter="2" aria-pressed="false">Đợt 2</button>
  <button type="button" data-filter="3" aria-pressed="false">Đợt 3</button>
</nav>

{groups}

<section><h2>Phần không cần AI tạo 3D</h2>
<div class="scroll"><table><thead><tr><th>Phần</th><th>Ai làm</th></tr></thead><tbody>{rows}</tbody></table></div></section>

<footer>Bản Markdown trong mã nguồn game: <code>docs/ASSET_PROMPTS.md</code>. Phong cách và thông số đầy đủ: <code>docs/ASSET_SPEC.md</code>.</footer>
</div>

<script>
document.querySelectorAll('.copy').forEach(function (button) {{
  button.addEventListener('click', function () {{
    var box = document.getElementById(button.dataset.target);
    var label = button.textContent;
    function done(text) {{ button.textContent = text; button.classList.add('done');
      setTimeout(function () {{ button.textContent = label; button.classList.remove('done'); }}, 1600); }}
    function fallback() {{ box.focus(); box.select(); done('Đã chọn — nhấn Ctrl/⌘+C'); }}
    if (navigator.clipboard && navigator.clipboard.writeText) {{
      navigator.clipboard.writeText(box.value).then(function () {{ done('Đã copy'); }}, fallback);
    }} else {{ fallback(); }}
  }});
}});
document.querySelectorAll('.filters button').forEach(function (button) {{
  button.addEventListener('click', function () {{
    var wave = button.dataset.filter;
    document.querySelectorAll('.filters button').forEach(function (b) {{ b.setAttribute('aria-pressed', String(b === button)); }});
    document.querySelectorAll('.card').forEach(function (card) {{ card.hidden = wave !== 'all' && card.dataset.wave !== wave; }});
    document.querySelectorAll('.group').forEach(function (group) {{ group.hidden = !group.querySelector('.card:not([hidden])'); }});
  }});
}});
</script>
"""

if __name__ == "__main__":
    md_path, html_path = sys.argv[1], sys.argv[2]
    open(md_path, "w").write(md())
    open(html_path, "w").write(page())
    longest = max(len(a[-1] + " " + STYLE) for _, items in ASSETS for a in items)
    print("ok, longest prompt", longest, "chars")
