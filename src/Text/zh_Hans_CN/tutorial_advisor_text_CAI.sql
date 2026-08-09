-- 针对当前 Firaxis 教程顾问消息和标注正文的无障碍专用说明。
-- 除非呈现方式依赖视觉或指针操作，否则保留原版玩法说明。

-- 单位选择、移动、战斗与行动。
UPDATE LocalizedText SET Text = '使用逗号键或句点键循环选择等待命令的单位，直到选中开拓者。' WHERE Tag = 'LOC_META_1_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '选中开拓者后，按 Tab 打开单位行动列表。使用上、下方向键，或输入“建立城市”的部分文字进行查找，然后按 Enter。也可以按 Alt 加 B。' WHERE Tag = 'LOC_META_2_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '使用逗号键或句点键循环选择等待命令的单位，直到选中勇士。' WHERE Tag = 'LOC_META_9_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '军事单位可通过移动到敌方单位所在单元格来发动攻击。选中勇士后，按 Alt 加 M，并将导航光标移到蛮族勇士处。按空格可在不发动攻击的情况下听取战斗预览。预览会播报交战双方和战况评估、双方预计受到的伤害、战斗力及修正值。第一次按 Enter 会准备攻击，并在预览后提示“再次按下以确认战斗”。再次按 Enter 即可攻击。' WHERE Tag = 'LOC_META_10_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '勇士拥有 2 点 [ICON_Movement] 移动力。选中勇士后，按 Shift 加 2 可听取其剩余移动力。若要立即移动一个单元格，向西北按 Alt 加 Q 或 Alt 加数字键盘 7，向东北按 Alt 加 E 或 Alt 加数字键盘 9，向西按 Alt 加 A 或 Alt 加数字键盘 4，向东按 Alt 加 D 或 Alt 加数字键盘 6，向西南按 Alt 加 Z 或 Alt 加数字键盘 1，向东南按 Alt 加 C 或 Alt 加数字键盘 3。若要前往自选位置或较远的目的地，请按 Alt 加 M，移动导航光标，按空格听取目的地信息，然后按 Enter。' WHERE Tag = 'LOC_META_16_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '平原和草原等开阔地形消耗 1 点 [ICON_Movement] 移动力，森林、丘陵和其他复杂地形则消耗 2 点或更多。将导航光标移到一个单元格并按 X，可听取其移动力消耗和其他地形数据。' WHERE Tag = 'LOC_META_17_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Alt 加 M，将导航光标移到教程指定的目的地，然后按 Enter 移动勇士。世界扫描器无需逐一查看每个单元格，便可查找已知地图对象。教程世界标记出现时，其单元格会列在“教程”类别中。使用 Control 加 Page Up 和 Control 加 Page Down 切换类别，Shift 加 Page Up 和 Shift 加 Page Down 切换子类别，Page Up 和 Page Down 切换组，Alt 加 Page Up 和 Alt 加 Page Down 切换项目。按 End 听取当前结果的方向和距离，或按 Home 将导航光标移到那里。' WHERE Tag = 'LOC_META_17b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '要探索部落村庄，请将一个单位移动到它所在的单元格。选中勇士后，使用快速移动或移动模式进入部落村庄单元格。' WHERE Tag = 'LOC_META_20_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '侦察兵拥有 3 点 [ICON_Movement] 移动力，因此能比许多其他单位走得更远。选中侦察兵后，按 Shift 加 2 听取其剩余移动力，再使用快速移动或移动模式朝未揭示的土地探索。' WHERE Tag = 'LOC_META_21_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '选中建造者后，使用快速移动或移动模式，到达城市旁边教程指定的平原单元格。' WHERE Tag = 'LOC_META_23_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '建造者位于该单元格并处于选中状态时，按 Tab，然后展开“改良设施”子菜单。此时会进入一个新列表；使用上、下方向键，或输入“农场”的部分文字，找到“建造改良设施：农场”，然后按 Enter。' WHERE Tag = 'LOC_META_24_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '建造者最多可建造 3 个改良设施，之后便会耗尽劳动力。这名建造者已经使用一次建造次数，还剩 2 次。选中建造者后，随时可以按 Shift 加 4 听取其剩余建造次数。' WHERE Tag = 'LOC_META_26_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '可以向单位下达跨越多个回合的移动命令，无需每回合分别下令。选中单位，按 Alt 加 M，将导航光标移到最终目的地，然后按 Enter。' WHERE Tag = 'LOC_META_28a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Control 加 S 将导航光标移到你当前的首都，或在世界扫描器的“城市”类别中找到它。然后按 Alt 加 M；如有需要，将光标移回首都，再按 Enter 命令勇士返回那里。' WHERE Tag = 'LOC_META_28_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '这里的石头是一种加成资源，可为城市额外提供 +1 [ICON_Production] 生产力。在此建造采石场后，加成会提高到 +2 [ICON_Production] 生产力。将导航光标移到一个单元格并按 W，可听取其中的资源、产出、工作状态、淡水和所有权信息。' WHERE Tag = 'LOC_META_31a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '使用快速移动，让建造者向东北移动一个单元格，到达石头资源处。抵达后按 Tab，展开“改良设施”子菜单，找到“建造改良设施：采石场”，然后按 Enter。' WHERE Tag = 'LOC_META_31b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '继续使用快速移动或跨回合移动命令，让侦察兵进行探索。' WHERE Tag = 'LOC_META_35_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '选中勇士后，按 Alt 加 F。也可以按 Tab，在单位行动列表中找到“驻防”，然后按 Enter。' WHERE Tag = 'LOC_META_36_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '不准备让军事单位继续前进时，通常可以让它驻防。驻防最多持续 2 回合，可在单位受到攻击时提高其 [ICON_Strength] 战斗力。“驻防”位于单位行动列表中，也可使用快捷键 Alt 加 F。' WHERE Tag = 'LOC_META_36a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '你的建造者还剩一次建造次数。选中后按 Shift 加 4 可听取剩余次数。你可以在丘陵上建造矿山以获得 [ICON_Production] 生产力，也可以在平原上建造农场以获得 [ICON_Food] 食物。移动和建造可能需要分别占用不同回合。' WHERE Tag = 'LOC_META_38a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '让开拓者和勇士一起移动的简便方法，是将它们编入护卫队形。队形命令位于单位行动列表中。' WHERE Tag = 'LOC_META_43a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '选中开拓者或勇士中的任意一个，按 Tab，找到与另一个单位“建立护卫队形”的命令，然后按 Enter。' WHERE Tag = 'LOC_META_43_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '该目的地距离当前位置有数个单元格。选中队形，按 Alt 加 M，将导航光标移到东南方教程指定的目的地，然后按 Enter 下达移动命令。途中可以让侦察兵自由探索。' WHERE Tag = 'LOC_META_44_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '开拓者能够行动时，在单位行动列表中使用“建立城市”，或按 Alt 加 B。如果它已没有剩余 [ICON_Movement] 移动力，请先结束回合。' WHERE Tag = 'LOC_META_57_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '每位 [ICON_GreatPerson] 伟人都能在指定地图位置激活一种或多种特殊加成。伟人位于正确位置时，在单位行动列表中使用“激活伟人”。所有加成使用完毕后，该伟人会消失。' WHERE Tag = 'LOC_META_138_BODY' AND Language = 'zh_Hans_CN';

-- 地图探索、单元格、城市与播报信息。
UPDATE LocalizedText SET Text = '游戏开始时，你的城市及附近土地已经揭示，世界其他部分则尚未探索。使用 Q、E、A、D、Z、C，或数字键盘上对应的方向键移动导航光标。光标播报会指出尚未探索的单元格。' WHERE Tag = 'LOC_META_14_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '勇士已经用完所有 [ICON_Movement] 移动力，本回合无法继续行动。选中勇士后按 Shift 加 2，可听到它已没有剩余移动力。生产和研究仍在进行，因此目前没有其他决定需要作出。' WHERE Tag = 'LOC_META_19_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '资源分为奢侈品资源、战略资源和加成资源。奢侈品资源提供 [ICON_Amenities] 宜居度，战略资源可用于生产强力单位，加成资源则增加产出。世界扫描器的“资源”类别可按这些类别和具体资源类型查找已知资源。将导航光标移到一个单元格并按 W，可听取其中的资源和产出。' WHERE Tag = 'LOC_META_30_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '选择城市位置时，应考虑附近的 [ICON_Food] 食物、资源和淡水。世界扫描器的“建议”类别会列出适合定居的位置；不过与现在一样，教程已经替你选好了目的地。用导航光标探索周围土地，并按 W 听取产出、资源、工作状态、淡水和所有权。' WHERE Tag = 'LOC_META_56_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '城市规模由其 [ICON_Citizen] 人口表示。选中城市并按波浪号键可听取摘要。' WHERE Tag = 'LOC_META_103_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '每座城市都会将周围土地纳入你的专属控制。用导航光标查看附近单元格，并按 W 听取所有权、产出和淡水信息。边界内的地貌与资源会显著影响城市。' WHERE Tag = 'LOC_META_104_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '每回合开始时，城市会从正在工作的单元格获得产出。选中城市并按 Shift 加 7，可听取总产出。将导航光标移到单个单元格并按 W，可听取该单元格的产出和工作状态。' WHERE Tag = 'LOC_META_106_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '城市边界内的每个单元格都能提供产出。[ICON_Food] 食物推动城市成长，[ICON_Production] 生产力则用于建造单位、建筑、区域和奇观。选中城市，按 Shift 加 3 听取成长信息，或按 Shift 加 7 听取总产出。' WHERE Tag = 'LOC_META_107_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '一个单元格必须由一名 [ICON_Citizen] 市民工作才能提供产出，每名市民只能在一个单元格工作。将导航光标移到一个单元格并按 W，可听取它是否正在被工作。' WHERE Tag = 'LOC_META_108_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '开始放置区域时，世界扫描器的“有效目标”类别会列出可以放置的单元格。在这些单元格之间移动导航光标，并按空格听取当前单元格的放置信息和相邻加成详情。' WHERE Tag = 'LOC_META_81_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '该单元格有两条边与山脉相邻，因此在这里建造学院可获得每回合 +2 [ICON_Science] 科技值。处于放置模式时，在导航光标处按空格，可听取当前单元格的放置和相邻加成信息。' WHERE Tag = 'LOC_META_82_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '将导航光标移到选定的单元格，按空格查看学院的放置信息，然后按 Enter 开始建造学院。' WHERE Tag = 'LOC_META_83_BODY' AND Language = 'zh_Hans_CN';

-- 生产与回合推进。
UPDATE LocalizedText SET Text = '选中城市后，按 Tab 打开城市行动列表，找到“更改生产”，然后按 Enter。也可以按 Alt 加反斜杠。' WHERE Tag = 'LOC_META_3_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '生产项目选择器是一棵包含单位、建筑、区域和奇观的树。使用上、下方向键在可见项目间移动，使用左、右方向键折叠或展开类别。也可以输入项目名称的一部分进行查找。在想要生产的项目上按 Enter。' WHERE Tag = 'LOC_META_4a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Control 加空格结束你的回合。' WHERE Tag = 'LOC_META_5_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Control 加空格继续下一回合。' WHERE Tag = 'LOC_META_13_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '再次按 Control 加空格继续下一回合。' WHERE Tag = 'LOC_META_19b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '除了训练单位，城市还可以建造纪念碑等建筑。在生产树中找到“纪念碑”，然后按 Enter。' WHERE Tag = 'LOC_META_27_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '继续让侦察兵探索。向建造者和侦察兵下达完命令后，按 Control 加空格结束回合。' WHERE Tag = 'LOC_META_39_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在城市行动列表中打开“更改生产”，进入生产项目选择器；也可以按 Alt 加反斜杠直接打开。' WHERE Tag = 'LOC_META_41b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在生产树中找到“开拓者”，然后按 Enter 开始训练。' WHERE Tag = 'LOC_META_41_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在生产树中找到“投石兵”，然后按 Enter。选好生产项目后，按 Control 加空格结束回合。' WHERE Tag = 'LOC_META_45_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '建造项目需要时间。生产项目选择器中的每个项目都会播报其成本和完成所需回合数。该估算会比较项目的 [ICON_Production] 生产力成本与城市每回合提供的 [ICON_Production] 生产力。选中城市后，按 Shift 加 2 可听取当前生产项目和剩余回合数。' WHERE Tag = 'LOC_META_5b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在生产树中找到“学院”，然后按 Enter，开始在这座城市建造学院。' WHERE Tag = 'LOC_META_80_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '选中城市后，按 Alt 加反斜杠或从城市行动列表打开“更改生产”。在生产树中找到“图书馆”，然后按 Enter。' WHERE Tag = 'LOC_META_87_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '要暂停一项生产任务并训练战斗单位，请打开“更改生产”，然后在生产树中选择该单位。之前的项目会保留已经积累的进度。' WHERE Tag = 'LOC_META_90_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在生产树中找到“建造者”，然后按 Enter 开始训练。' WHERE Tag = 'LOC_META_102_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '现在由你决定这座城市生产什么。生产树中的实用选项包括：用于修建改良设施的建造者、扩充军队的战斗单位，或可提供 [ICON_Food] 食物和 [ICON_Housing] 住房的粮仓。' WHERE Tag = 'LOC_META_110_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Shift 加空格可听取阻止你结束回合的事项。按 Control 加 Shift 加空格可打开完整的回合阻塞事项列表。这座城市已经完成生产，因此必须为它选择下一个生产项目。' WHERE Tag = 'LOC_META_11a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '“选择生产项目”是当前唯一的回合阻塞事项，因此按 Control 加空格可直接将其打开。也可以按 Control 加 Shift 加空格打开回合阻塞事项列表，找到“选择生产项目”，然后按 Enter。' WHERE Tag = 'LOC_META_11_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '一名建造者已加入城市的生产队列，需要数个回合才能完成。现在没有其他决定需要作出，请按 Control 加空格结束回合。' WHERE Tag = 'LOC_META_13a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '已经开始研究制陶术。移动侦察兵后，按 Control 加空格结束回合。' WHERE Tag = 'LOC_META_117_BODY' AND Language = 'zh_Hans_CN';

-- 研究、市政、政体与其他界面。
UPDATE LocalizedText SET Text = '“选择研究”是当前回合行动时，按 Control 加空格可打开研究选择器。也可以按 Control 加 Shift 加空格打开回合阻塞事项列表，使用上、下方向键，或输入“选择研究”的部分文字找到该研究阻塞事项，然后按 Enter。' WHERE Tag = 'LOC_META_6_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '研究选择器会打开“可用研究”树。使用上、下方向键，或输入“采矿业”的部分文字找到该科技，然后按 Enter 开始研究。' WHERE Tag = 'LOC_META_7_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在“可用研究”树中找到“制陶术”，然后按 Enter。' WHERE Tag = 'LOC_META_33_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '你的文明必须始终研究一项科技。采矿业已经完成，因此结束回合前必须选择下一项科技。' WHERE Tag = 'LOC_META_116_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '“选择研究”是当前回合行动时，按 Control 加空格打开研究选择器。' WHERE Tag = 'LOC_META_332_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在“可用研究”树中找到“灌溉”，然后按 Enter。' WHERE Tag = 'LOC_META_SELECT_IRRIGATION' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '写作已经研究完成，请从“可用研究”树中选择另一项科技。畜牧业和铸铜术都是实用的选择。' WHERE Tag = 'LOC_META_84_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '科技发现会通过前置条件通向后续科技。科技树会显示这些路径，以及每项科技解锁的内容，并使用与市政树相同的网格、树视图和关系图视图。' WHERE Tag = 'LOC_META_46_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Control 加 Shift 加 R 打开科技树。' WHERE Tag = 'LOC_META_46a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '科技树首次打开时使用网格视图，此后会记住上次选择的视图。在网格视图中，时代构成列，每个时代内的研究层级从左到右排列。导航方式与市政树相同，可使用方向键和按键搜索。“视图”下拉框包含“网格”“关系图”和“树视图”。Alt 加 1 选择网格，Alt 加 2 选择关系图，Alt 加 3 选择树视图。在关系图视图中，按右方向键前往当前科技解锁的科技，按左方向键前往一项前置科技，按上或下方向键在上一次连接的备选项之间循环。焦点控件阅读器可让你逐节听取焦点项目的详细信息。Alt 加上方向键和 Alt 加下方向键会移动并朗读上一节和下一节，Alt 加 Home 和 Alt 加 End 则跳转并朗读第一节和最后一节。' WHERE Tag = 'LOC_META_47_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '已完成的科技会在科技树中播报为“已完成”。制陶术现在已标记为完成。' WHERE Tag = 'LOC_META_48_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '当前可以研究的科技会在科技树中播报为“可用”。' WHERE Tag = 'LOC_META_49_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '前置条件尚未完成的科技会播报为“受阻”。使用焦点控件阅读器可听取其要求和其他详情。在备用的树视图中，也可以按右方向键展开科技，将其前置条件、解锁内容和后续科技作为分支浏览。' WHERE Tag = 'LOC_META_50_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在科技树中找到“写作”，然后按 Enter 开始研究。' WHERE Tag = 'LOC_META_51_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '写作现在会在科技树中播报为“当前研究”。其工具提示包含完成研究所需的回合数和当前进度。' WHERE Tag = 'LOC_META_52_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '科技的工具提示还会列出完成研究后解锁或揭示的单位、建筑、奇观、能力和资源。' WHERE Tag = 'LOC_META_53A_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Escape 关闭科技树。' WHERE Tag = 'LOC_META_54a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在万神殿列表中，使用上、下方向键，或输入万神殿名称的一部分进行查找。在选中的万神殿上按 Enter，查看确认对话框，然后在“确认万神殿”上按 Enter。' WHERE Tag = 'LOC_META_129d' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Control 加 L 打开宗教界面及其中的万神殿选项。' WHERE Tag = 'LOC_META_129b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 F3 打开 [ICON_GreatPerson] 伟人界面。在伟人树中，使用方向键，或输入伟人姓名的一部分，找到可以招募的候选人。按 Tab 直到焦点移到“招募”，然后按 Enter。' WHERE Tag = 'LOC_META_136b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '世界排名会追踪每种胜利条件的状态。' WHERE Tag = 'LOC_META_119_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 F8 打开世界排名。' WHERE Tag = 'LOC_META_119a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '世界排名打开时位于“总览”选项卡。表格视图会按所有可用胜利类型比较每位竞争者。使用 Control 加 Tab 和 Control 加 Shift 加 Tab 切换选项卡。' WHERE Tag = 'LOC_META_120_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '世界排名的其他选项卡会提供每种胜利的详细信息。Alt 加 1 为整个界面选择表格视图，Alt 加 2 选择树视图。准备继续时按 Escape。' WHERE Tag = 'LOC_META_121_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '如果需要进一步了解教程中的内容，请按 F1 打开文明百科。“无障碍模组”章节还记录了 CAI 控件、游戏命令和界面导航方式。' WHERE Tag = 'LOC_META_123_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在政体界面按 Control 加 Tab，切换到“政策”选项卡。' WHERE Tag = 'LOC_META_95b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在“政策”选项卡中，使用方向键找到空的军事政策槽，然后按 Enter。在政策选择树中，使用方向键，或输入“纪律”的部分文字找到该政策，然后按 Enter。接着在空的经济政策槽中以相同方式选择“城市规划”。按 Tab 直到焦点移到“确认政策”，然后按 Enter。' WHERE Tag = 'LOC_META_96_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Control 加 P 打开政体界面。' WHERE Tag = 'LOC_META_93b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '现在需要选择一项新市政。下一步会打开市政树，其中的市政路径按时代和研究层级排列。' WHERE Tag = 'LOC_META_99a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Control 加 Shift 加 C 打开市政树。' WHERE Tag = 'LOC_META_99b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '市政树首次打开时使用网格视图，此后会记住上次选择的视图。“视图”下拉框包含“网格”“关系图”和“树视图”；Alt 加 1、Alt 加 2 和 Alt 加 3 会按此顺序选择这些视图。在网格视图中，使用上、下方向键在同一层级内移动，使用左、右方向键在层级之间移动，也可以输入市政名称的一部分进行查找。技艺是本教程的下一项市政。' WHERE Tag = 'LOC_META_100_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在市政树中找到“技艺”，然后按 Enter。' WHERE Tag = 'LOC_META_100b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '按 Escape 关闭市政树。' WHERE Tag = 'LOC_META_100c_BODY' AND Language = 'zh_Hans_CN';

-- 贸易路线选择器。
UPDATE LocalizedText SET Text = '贸易路线选择器会在目的地树中列出可以抵达的城市。使用上、下方向键在可见目的地之间移动，使用左、右方向键折叠或展开分组。也可以输入城市名称的一部分进行查找。选中商人后，按 Shift 加 6 可听取其陆地和海上路线范围；如果已有路线，按 Shift 加 8 可听取当前路线和产出。贸易站可以让之后的路线延伸得更远。' WHERE Tag = 'LOC_META_144_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '每个目的地都包含距离和产出信息。在目的地树中找到所需城市，然后按 Enter。' WHERE Tag = 'LOC_META_145b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '在确认对话框中查看选中的路线。“开始路线”是默认按钮，因此按 Enter 即可开始。如果需要在“开始路线”和“取消”之间移动，请使用左或右方向键。' WHERE Tag = 'LOC_META_145c_BODY' AND Language = 'zh_Hans_CN';

-- 首次使用的信息键与后续概念指导。
UPDATE LocalizedText SET Text = '正如建造新单位需要 [ICON_Production] 生产力，研究新科技需要 [ICON_Science] 科技值。按 R 可听取每回合科技值和当前研究进度。' WHERE Tag = 'LOC_META_111_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '通过积累 [ICON_Culture] 文化值，你刚刚解锁了法典，其中包含你的第一个政体：酋邦。按 P 可听取每回合文化值和当前市政进度。' WHERE Tag = 'LOC_META_93a_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '你可能已经注意到，城市每回合都会产生少量 [ICON_Faith] 信仰值。[NEWLINE][NEWLINE]某些建筑、区域和政策会随时间提供 [ICON_Faith] 信仰值。按 F 可听取信仰值余额和每回合信仰值。' WHERE Tag = 'LOC_META_128_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '你的城市已经完成纪念碑建筑的生产。所有建筑都会以特定方式促进城市发展。纪念碑会提高城市产生的 [ICON_Culture] 文化值，使其影响力扩展到更多单元格。将导航光标移到城市单元格，可在单元格摘要中听取城市建筑；也可以在那里按 B，听取建筑和其他地理详情。' WHERE Tag = 'LOC_META_40_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '你的第一座城市的 [ICON_Citizen] 人口已经从 1 增长到 2。只要城市食物充足且居民保持幸福，城市就会继续成长。城市中的 [ICON_Citizen] 市民会在周围单元格和改良设施上工作，从而增加产出。更高的 [ICON_Citizen] 人口能加快 [ICON_Science] 科技研究、城市 [ICON_Production] 生产和 [ICON_Culture] 文化发展。选中城市后，按 Shift 加 6 可听取人口、住房和建筑信息。' WHERE Tag = 'LOC_META_125_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '请记住：建造者只能在你的城市边界内修建改良设施。[NEWLINE][NEWLINE]城市产生 [ICON_Culture] 文化值后，边界会逐渐扩张，使你能够利用更多资源。选中城市后，按 Shift 加 4 可听取边界扩张进度。' WHERE Tag = 'LOC_META_38b_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '远程单位的防御力通常低于近战单位，因此应让它们靠近其他类型的友方单位以获得保护。选中单位后，按 Shift 加 6 可听取其战斗力、远程或轰炸战斗力，以及射程。' WHERE Tag = 'LOC_META_104_OTHER_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '本教程的其余部分将帮助你取得第一次统治胜利。[NEWLINE][NEWLINE]统治胜利的目标，是让你的文明成为最后一个仍占领己方 [ICON_Capital] 首都的文明。[NEWLINE][NEWLINE]在本教程中，你必须占领对手的 [ICON_Capital] 首都，同时阻止对方夺取你的首都。[NEWLINE][NEWLINE]三项可选目标会帮助你实现这一点。按 Control 加 Shift 加 T 打开教程目标列表。教程目标也会显示在通知面板中。' WHERE Tag = 'LOC_META_122_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '你可以放弃不想要的 [ICON_GreatPerson] 伟人。之后其他玩家可以招募该伟人；此决定无法撤销，而你的 [ICON_GreatPerson] 伟人点数会保留到未来的招募机会。将焦点移到该伟人并按 Delete 即可放弃。也可以按 Tab 浏览该伟人可用的行动按钮和生平。' WHERE Tag = 'LOC_META_140_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '你的文明只能建立有限数量的 [ICON_TradeRoute] 贸易路线。商业中心和港口区域可以提高这项容量。按 G 可同时听取金币余额与收入、当前贸易路线和路线容量。' WHERE Tag = 'LOC_META_142_BODY' AND Language = 'zh_Hans_CN';
UPDATE LocalizedText SET Text = '游戏过程中，请考虑如何与邻国相处，并仔细观察他们以了解其策略。按 F4 打开已遇见领袖的列表，然后在一位领袖上按 Enter，打开与其相关的详细外交界面。' WHERE Tag = 'LOC_META_157_BODY' AND Language = 'zh_Hans_CN';
