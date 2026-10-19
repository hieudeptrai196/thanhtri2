# THÀNH TRÌ — Bộ prompt cho AI tạo 3D

> 2026-10-19. Dùng cho AI tạo 3D từ chữ / ảnh (Meshy, Tripo, Rodin…). Mỗi khối **Prompt** dán nguyên vào ô prompt, mỗi lần một asset.
> Bản đầy đủ về phong cách và thông số: [`ASSET_SPEC.md`](ASSET_SPEC.md). Prompt viết tiếng Anh vì các công cụ này hiểu tiếng Anh tốt nhất.

## Cài đặt chung cho mọi asset

- Chế độ **Text to 3D** (hoặc Image to 3D nếu có ảnh mẫu). Nếu có chọn phong cách: chọn **Stylized / Cartoon**, không chọn Realistic.
- Bật **texture PBR**. Xuất file **GLB**.
- **Số tam giác mục tiêu** (target polycount / remesh): theo cột *Tam giác* của từng asset.
- Nếu có ô **Negative prompt**: dán đoạn Negative ở dưới.
- Mỗi asset tạo **3–4 bản**, chọn bản **nhìn rõ nhất từ trên cao chéo xuống** (game nhìn nghiêng 35°, nhân vật chỉ cao ~60 px trên màn hình).

## Giữ phong cách đồng bộ

- Làm **CH-03 Võ tướng trước**. Khi ưng, chụp ảnh model đó.
- Các asset sau: nếu công cụ cho dùng **ảnh tham chiếu phong cách** (style reference / image prompt), đưa ảnh Võ tướng vào cùng với prompt chữ.
- Giữ nguyên **đoạn Style** ở cuối mọi prompt (đã gộp sẵn trong từng prompt bên dưới).

## Nhân vật và quái: rig + animation

- Dùng tính năng **auto-rig humanoid** của công cụ (nhân vật để A-pose đúng như prompt).
- Animation cần lấy từ thư viện của công cụ (nếu có): **idle, run, attack (chém kiếm), hit, death**; có thêm thì lấy: **walk, dash/roll, kneel (quỳ), lie down (gục), cheer/cast (dùng kỹ năng), hammer/chop**.
- Tải về **GLB có rig** + từng animation (hoặc một GLB chứa nhiều animation).
- Animation nào công cụ không có: Claude tự làm hoặc thay thế trong Godot.

## Gửi file cho Claude

- Đặt tên file theo cột *Tên file* (vd `ch03_general.glb`), gửi **xong cái nào gửi cái đó**.
- Không cần chỉnh tỉ lệ, gốc tọa độ, hướng mặt, hay lắp ráp: Claude làm hết trong Godot (gắn bánh xe vào thân, nỏ vào tháp, module lên nóc).
- Thứ tự nhanh nhất: **FT-01 + FT-01w → CH-03 → EN-01 → ST-01 + ST-01b → WD-01a/b + WD-01s → FM-01, FM-03** (hết đợt 1), rồi các mục đợt 2.

## Negative prompt (dán vào ô Negative nếu công cụ có)

```
realistic, photorealistic, Chinese dragon, Japanese torii, samurai armor, tiny noisy details, thin fragile parts, text, logo, ground base, pedestal, multiple objects, blurry texture
```

## Nhân vật — 5 class (mỗi class 1 model riêng)

### CH-03 · Võ tướng — làm đầu tiên, dùng làm mẫu phong cách

- Tên file: `ch03_general.glb` · Tam giác: **8.000** · Đợt 1 · A-pose. Auto-rig humanoid. Màu nhận diện: đỏ.

```
Vietnamese general warrior, Ly-Tran dynasty lamellar armor with bronze plates and red cloth, red headscarf under a bronze helmet with short plume, broad shoulders, big curved saber in right hand. Heroic chibi proportions about 3.5 heads tall, A-pose, full body, front view. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### CH-01 · Công binh

- Tên file: `ch01_engineer.glb` · Tam giác: **8.000** · Đợt 2 · A-pose. Màu nhận diện: cam đồng.

```
Vietnamese army engineer, copper-orange tunic and headband, leather tool belt with nails and measuring rope, oversized wooden mallet in right hand, small bundle of planks on the back. Heroic chibi proportions about 3.5 heads tall, A-pose, full body, front view. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### CH-02 · Tiều phu

- Tên file: `ch02_woodcutter.glb` · Tam giác: **8.000** · Đợt 2 · A-pose. Màu nhận diện: xanh lá. Gùi to = túi đồ gấp đôi.

```
Vietnamese woodcutter, green and brown peasant clothes, green bandana, sturdy legs with leg wraps, big axe in right hand, large woven bamboo basket backpack. Heroic chibi proportions about 3.5 heads tall, A-pose, full body, front view. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### CH-04 · Thầy pháp

- Tên file: `ch04_shaman.glb` · Tam giác: **8.000** · Đợt 2 · A-pose. Màu nhận diện: tím.

```
Vietnamese folk shaman, purple robe with yellow paper talismans, tall cloth hat, wooden staff with small bronze bells and hanging charms in right hand, calm mystical look. Heroic chibi proportions about 3.5 heads tall, A-pose, full body, front view. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### CH-05 · Thợ máy

- Tên file: `ch05_mechanic.glb` · Tam giác: **8.000** · Đợt 2 · A-pose. Màu nhận diện: xám thép.

```
Vietnamese blacksmith mechanic, steel-grey tunic, thick leather apron, bronze goggles on forehead, soot smudges, big bronze wrench in right hand, small bellows on the back. Heroic chibi proportions about 3.5 heads tall, A-pose, full body, front view. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

## Quái (truyền thuyết Việt)

### EN-01 · Quỷ rừng — quái thường

- Tên file: `en01_forest_demon.glb` · Tam giác: **2.000** · Đợt 1 · Rất nhiều con cùng lúc → để polycount thấp. Auto-rig humanoid. Mắt phát sáng.

```
Forest demon from Vietnamese folklore, hunched humanoid made of rotten dark wood and moss, long arms with claws, glowing yellow eyes, dark red and moss green colors, menacing but cartoony, A-pose, full body. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### EN-02 · Ma trơi — quái nhanh

- Tên file: `en02_will_o_wisp.glb` · Tam giác: **1.500** · Đợt 3 · Nhỏ, cao ~1 m.

```
Will-o'-the-wisp ghost from Vietnamese folklore, small floating blue-green flame spirit with a glowing face and two tiny clawed arms, wispy flame tail instead of legs, cartoony and creepy. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### EN-03 · Quỷ nhập tràng — quái trâu

- Tên file: `en03_ghoul.glb` · Tam giác: **4.000** · Đợt 3 · To, cao ~2.4 m.

```
Huge bloated undead ghoul from Vietnamese folklore, torn white funeral shroud, grey-green skin, heavy fists, slow and strong, glowing pale eyes, cartoony, A-pose, full body. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### EN-04a · Boss Ngư tinh

- Tên file: `en04_fish_demon.glb` · Tam giác: **15.000** · Đợt 3 · Boss, cao ~6 m.

```
Giant fish demon boss from the Lac Long Quan legend, armored scales, huge jaws with fangs, fin claws, walks on stubby legs, teal and gold colors, glowing eyes, epic and cartoony. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### EN-04b · Boss Hồ tinh

- Tên file: `en04_fox_demon.glb` · Tam giác: **15.000** · Đợt 3 · Boss, cao ~5 m.

```
Giant nine-tailed fox demon boss from Vietnamese legend, white and crimson fur, nine flaming tails, sly face with glowing eyes, bronze ornaments, standing on four legs, epic and cartoony. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### EN-04c · Boss Mộc tinh

- Tên file: `en04_tree_demon.glb` · Tam giác: **15.000** · Đợt 3 · Boss, cao ~7 m.

```
Giant ancient tree demon boss from Vietnamese legend, banyan tree body with hanging aerial roots as beard, angry carved face, root legs and branch arms, moss and glowing amber eyes, epic and cartoony. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

## Pháo đài — tòa thành chạy bánh xe (thân và bánh xe tạo riêng, Claude lắp)

### FT-01 · Thân pháo đài cấp Gỗ (không bánh xe)

- Tên file: `ft01_fortress_wood.glb` · Tam giác: **30.000** · Đợt 1 · Footprint vuông, thấp và rộng. Nóc phẳng ở giữa để đặt nỏ. KHÔNG có bánh xe.

```
Body of a mobile siege citadel without wheels: miniature ancient Vietnamese Co Loa fortress, square low wide hull of ironwood log palisade walls with sharpened stakes, iron bands and rivets, bronze battering ram at the front, small gatehouse with upturned curved roof, flags, flat open roof deck in the middle. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FT-01w · Bánh xe (dùng 4–6 cái)

- Tên file: `ft01_wheel.glb` · Tam giác: **2.000** · Đợt 1 · Một bánh duy nhất, nhìn ngang. Claude nhân bản và quay trong game.

```
Single giant wooden war wagon wheel, thick chunky spokes, heavy iron rim with rivets, bronze hub cap with a Dong Son drum star pattern, side view. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FT-02 · Thân pháo đài cấp Đá (không bánh xe)

- Tên file: `ft02_fortress_stone.glb` · Tam giác: **30.000** · Đợt 2 · Cùng hình dáng với FT-01, đổi vật liệu.

```
Body of a mobile siege citadel without wheels: miniature ancient Vietnamese Co Loa fortress, square low wide hull of rammed earth and grey stone brick walls with crenellations, thick iron bands, bronze battering ram at the front, gatehouse with upturned tiled roof, flags, flat open roof deck in the middle. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FT-03 · Thân pháo đài cấp Bọc đồng (làm sau)

- Tên file: `ft03_fortress_bronze.glb` · Tam giác: **30.000** · Đợt 3 · Cùng hình dáng, cấp cao nhất.

```
Body of a mobile siege citadel without wheels: miniature ancient Vietnamese fortress clad in engraved bronze plates with Dong Son drum motifs and Lac bird patterns, stone base, golden battering ram, grand gatehouse with upturned roof, banners, flat open roof deck in the middle. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

## Module trên pháo đài (tạo riêng, Claude gắn lên thân)

### FM-01 · Nỏ liên châu

- Tên file: `fm01_repeating_crossbow.glb` · Tam giác: **2.500** · Đợt 1 · Nỏ trên nóc thành, xoay theo hướng ngắm. Rộng ~2.2 m.

```
Large repeating crossbow siege weapon on a rotating wooden turntable base, ironwood frame with bronze fittings, magazine of arrows on top, hand crank on the back, chunky. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FM-03 · Thang leo lên nỏ

- Tên file: `fm03_ladder.glb` · Tam giác: **500** · Đợt 1 · Cao ~5 m, áp vào tường.

```
Sturdy wooden siege ladder leaning against a wall, thick bamboo rails lashed with rope, about 5 meters tall. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FM-04 · Dầu sôi

- Tên file: `fm04_boiling_oil.glb` · Tam giác: **1.500** · Đợt 2 · ~1.2 m.

```
Bronze cauldron of boiling oil on a wooden stand with a tilting pouring chute, smoke and bubbling oil, Dong Son patterns on the cauldron. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FM-05 · Lò lửa đốt Than

- Tên file: `fm05_coal_furnace.glb` · Tam giác: **1.500** · Đợt 2 · ~1.2 m, lửa phát sáng.

```
Small coal furnace of clay bricks with an iron door glowing orange, short chimney with smoke, coal pile beside it, bronze trim. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FM-07 · Nỏ thần (trên vọng lâu phía trước)

- Tên file: `fm07_divine_crossbow.glb` · Tam giác: **4.000** · Đợt 2 · Chi tiết đẹp nhất trên thành.

```
Legendary giant magic crossbow of King An Duong Vuong, golden bronze body engraved with Dong Son motifs, glowing golden turtle-claw trigger, mounted on an ornate wooden stand, majestic. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### FM-08 · Chông gai (đoạn tường chông)

- Tên file: `fm08_stakes.glb` · Tam giác: **800** · Đợt 2 · Một đoạn dài ~3 m, Claude lặp quanh chân tường.

```
Row of sharpened wooden and bamboo stakes tied with rope, 3 meters long strip, angled outward, for the base of a fortress wall. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

## Công trình ngoài thực địa

### ST-01 · Tháp nỏ — phần thân (không có nỏ)

- Tên file: `st01_turret_base.glb` · Tam giác: **2.500** · Đợt 1 · Cao ~1.6 m. Phần nỏ dùng chung model ST-01b.

```
Small wooden watchtower base for a crossbow turret, octagonal log frame with stone footing, iron bands, rope lashings, flat platform on top (no weapon), about 1.6 meters tall. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### ST-01b · Tháp nỏ — đầu nỏ xoay

- Tên file: `st01_turret_bow.glb` · Tam giác: **1.500** · Đợt 1 · Rộng ~1.4 m, gắn lên ST-01.

```
Compact mounted crossbow head for a defense turret, ironwood bow with bronze tips, loaded arrow, small rotating pivot underneath, chunky. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### ST-01f · Tháp nỏ — gấp gọn để vác

- Tên file: `st01_turret_folded.glb` · Tam giác: **1.000** · Đợt 2 · ~0.9 × 0.9 × 0.6 m, nhân vật vác trên lưng.

```
Folded wooden crossbow turret packed into a compact bundle tied with rope and straps, logs and bow parts, ready to carry on the back. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### ST-02 · Rào gỗ

- Tên file: `st02_barricade.glb` · Tam giác: **2.000** · Đợt 2 · 3 × 1.4 × 0.8 m.

```
Wooden spiked barricade, cheval de frise made of sharpened logs and bamboo tied with rope, 3 meters wide, sturdy and chunky. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### ST-02f · Rào gỗ — gấp gọn để vác

- Tên file: `st02_barricade_folded.glb` · Tam giác: **800** · Đợt 2 · ~0.9 × 0.9 × 0.6 m.

```
Bundle of sharpened logs and bamboo stakes tied tightly with rope, compact, ready to carry on the back. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### ST-X · Đống đổ nát (công trình bị phá)

- Tên file: `st_debris.glb` · Tam giác: **1.000** · Đợt 2 · Dùng chung cho mọi công trình.

```
Pile of broken wooden planks, splintered logs and torn rope from a destroyed small wooden structure, low flat pile. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

## Tài nguyên & thế giới

### WD-01a · Cây A (cho Gỗ)

- Tên file: `wd01_tree_a.glb` · Tam giác: **1.500** · Đợt 1 · Cao 3–5 m.

```
Stylized broadleaf tree from a Vietnamese forest, thick twisted trunk, round chunky leaf clusters, lush green, about 4 meters tall. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-01b · Cây B (cho Gỗ)

- Tên file: `wd01_tree_b.glb` · Tam giác: **1.500** · Đợt 1 · Cao 3–5 m.

```
Stylized clump of tall green bamboo stalks with leaves, Vietnamese countryside, about 5 meters tall. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-01c · Cây C (cho Gỗ)

- Tên file: `wd01_tree_c.glb` · Tam giác: **1.500** · Đợt 2 · Cao 4–5 m.

```
Stylized small banyan tree with hanging aerial roots, wide canopy, chunky trunk, Vietnamese village style. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-01s · Gốc cây (khi hết gỗ)

- Tên file: `wd01_stump.glb` · Tam giác: **500** · Đợt 1

```
Chopped tree stump with fresh cut top, roots and a few wood chips, stylized. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-02 · Mỏ than

- Tên file: `wd02_coal_rock.glb` · Tam giác: **1.500** · Đợt 2 · ~2.2 × 1.6 × 2.2 m.

```
Limestone rock outcrop with thick shiny black coal veins and a few coal chunks at the base, stylized. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-03a · Đống đồ rơi — Gỗ

- Tên file: `wd03_pile_wood.glb` · Tam giác: **600** · Đợt 2 · ~0.7 m.

```
Small bundle of firewood logs tied with rope, stylized pickup item. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-03b · Đống đồ rơi — Than

- Tên file: `wd03_pile_coal.glb` · Tam giác: **600** · Đợt 2 · ~0.7 m.

```
Small woven basket full of black coal chunks, stylized pickup item. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-03c · Đống đồ rơi — Đồng

- Tên file: `wd03_pile_bronze.glb` · Tam giác: **600** · Đợt 2 · ~0.7 m.

```
Small pile of bronze scraps, bronze arrowheads and a broken bronze plate with Dong Son pattern, shiny, stylized pickup item. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-04 · Mốc điểm dừng (cổng)

- Tên file: `wd04_stop_gate.glb` · Tam giác: **6.000** · Đợt 2 · Rộng ~10 m, pháo đài đi qua.

```
Ancient Vietnamese three-entrance temple gate (tam quan), wooden pillars, upturned curved tiled roofs, red and gold, lanterns hanging, about 10 meters wide. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-07a · Đạo cụ — hàng rào tre

- Tên file: `wd07_bamboo_fence.glb` · Tam giác: **500** · Đợt 2 · Dài ~3 m.

```
Short woven bamboo fence section, Vietnamese village, 3 meters long. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-07b · Đạo cụ — miếu nhỏ

- Tên file: `wd07_shrine.glb` · Tam giác: **1.500** · Đợt 2 · ~1.5 m.

```
Small roadside Vietnamese shrine with upturned tiled roof on a brick base, incense pot, red and moss colors. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-07c · Đạo cụ — chum và bao tải

- Tên file: `wd07_jars_sacks.glb` · Tam giác: **800** · Đợt 2

```
Group of two clay water jars and a rice sack, Vietnamese countryside props. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-07d · Đạo cụ — đá

- Tên file: `wd07_rocks.glb` · Tam giác: **500** · Đợt 2

```
Cluster of three rounded mossy limestone rocks, stylized. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-07e · Đạo cụ — cờ hiệu

- Tên file: `wd07_banner.glb` · Tam giác: **500** · Đợt 2

```
Tall bamboo pole with a triangular red war banner with bronze drum emblem, stylized. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

### WD-07f · Đạo cụ — đèn lồng trên cột

- Tên file: `wd07_lantern.glb` · Tam giác: **500** · Đợt 2

```
Wooden post with a hanging red silk lantern, stylized, Vietnamese village. Stylized 3D game asset, chunky exaggerated proportions, bold bevelled shapes, hand-painted textures with moderate detail (wood grain, rivets, rope, worn edges), vibrant warm colors, ancient Vietnamese style, clean readable silhouette, game-ready, single object, no base, plain background.
```

## Phần không cần AI tạo 3D

| Phần | Ai làm |
|---|---|
| Mặt đất, dải đường | Claude làm bằng shader trong Godot (AI 3D không tạo texture lặp liền được). |
| Hiệu ứng (nổ, chém, khói, khiên, bùa…) | Claude làm bằng hạt / shader trong Godot. |
| Icon tài nguyên, công trình, chân dung class | Claude chụp từ chính các model 3D ở trên trong Godot → đồng bộ phong cách, không cần AI vẽ riêng. |
| Khung thẻ, nút, thanh máu, logo | Cần AI tạo ảnh 2D (Midjourney, GPT Image…): báo Claude nếu muốn bộ prompt ảnh; nếu không, Claude tiếp tục vẽ bằng code. |
| Font chữ tiếng Việt | Claude chọn font miễn phí bản quyền (giấy phép OFL) — cần bạn cho phép tải. |
| Âm thanh | Claude lo (hệ thống + âm tạm; âm thật từ thư viện CC0 nếu bạn cho phép tải). |
