-- Services
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

-- Player Variables
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

-- Remote Variables
local DataEvent: RemoteEvent = ReplicatedStorage:WaitForChild("dataRemoteEvent")
local Remotes = ReplicatedStorage:WaitForChild("remotes")

-- Misc Variables
local Dev = true

-- Config Variables
local Config = {
	GameSettings = {
		DoBonusBoss = true,
		ReturnOnInventoryLimit = 999,
		RetryDungeon = true,
		DisableDodging = false,
		Optimizations = {
			PerformanceMode = true,
			DestroyGear = true,
			FpsBoost = true,
		},
		BossSettings = {
			EnemyDistance = 50,
			CastingRange = 75,
			Teleports = {
				Enabled = true,
				Distance = 10,
				Delay = 0.2,
			},
		},
		MobSettings = {
			EnemyDistance = 30,
			CastingRange = 40,
			Teleports = {
				Enabled = true,
				Distance = 10,
				Delay = 0.2,
			},
		},
		Miscellaneous = {
			ShowTarget = true,
			ShowPath = true,
		},
	},
	LobbySettings = {
		Miscellaneous = {
			CharacterSelection = 1, -- Accepted Values: 1, 2, 3, 4
			CollectDailyReward = true,
		},
		GameCreation = {
			MultiFarm = {
				Enabled = true,
				HostAccount = "AvgByfronEnjoyer",
				JoinerAccounts = { "TheAuthenticName2" },
			},
			DungeonSettings = {
				Dungeon = "Yokai Peak",
				Difficulty = "Nightmare",
				Hardcore = true,
				AutoSelectHighest = true,
			},
		},
		AutoEquipGear = {
			Enabled = true,
			Upgrade = true,
			EquipSpells = false,
			Class = "Warrior",
		},
		AutoStat = {
			Enabled = false,
			Class = "Warrior",
		},
		AutoSell = {
			Enabled = true,
			TestSell = true,
			ItemLevelRequirement = 216,
			Keep2Spells = true,
			KeepRarities = {
				["ultimate"] = true,
				["legendary"] = true,
				["epic"] = false,
				["rare"] = false,
				["uncommon"] = false,
				["common"] = false,
			},
			KeepList = {
				["Enhanced Inner Rage"] = { "legendary" },
				["Enhanced Inner Focus"] = { "legendary" },
				["Unstable Warp"] = { "legendary" },
				["Gravity Leap"] = { "legendary" },
				["Voidborn's Embrace"] = { "legendary" },
				["Voidborns's Malice"] = { "legendary" },
				["Voidborn Warrior Helmet"] = { "epic", "rare" },
				["Voidborn Warrior Armor"] = { "epic", "rare" },
				["Voidborn Mage Helmet"] = { "epic", "rare" },
				["Voidborn Mage Armor"] = { "epic", "rare" },
			},
		},
	},
	Universal = {
		CustomUi = {
			Enabled = true,
			Exp = "",
			Gold = "",
			Name = "",
			Level = "",
			Health = "",
			Image = "",
		},
		Webhook = {
			Enabled = true,
			Url = "",
		},
	},
}

-- Global Functions
function Log(level: string, title: string, msg: string)
	if level == "info" then
		print(`[{title}]: {msg}`)
	elseif level == "dev" and Dev == true then
		warn(`[{title}]: {msg}`)
	else
		return
	end
end

function GetInventory(): {}
	return Remotes:WaitForChild("reloadInvy"):InvokeServer()
end

-- Auto Equip Functions
local function CalculatePot(baseStat: number, maxUpgrades: number): number
	local CurrentUpgrades = 0

	for i = 1, maxUpgrades do
		CurrentUpgrades = baseStat * 0.05

		if CurrentUpgrades > 10 then
			CurrentUpgrades = 10
		end

		baseStat += CurrentUpgrades
	end

	return math.floor(baseStat)
end

local function CalculateCost(totalUpgrades: number, currentUpgrades: number): number
	local i = 0
	local r = 100

	for o = 1, totalUpgrades do
		local a = 0
		if o > 1 then
			local s = 1.06 * r + 50
			if 220 < s - r then
				a = r + 220
			else
				a = s
			end
		else
			a = r
		end

		if currentUpgrades < o then
			if o <= 466 then
				i += 100000
				a = 100000
			end
		end
		r = a
	end
	return i
end

if game.PlaceId == 2414851778 then
	-- Check For Character
	if Workspace:FindFirstChild(Player.Name) == nil then
		-- Press Play
		if PlayerGui.introGui.Enabled then
			repeat
				task.wait(1)
			until PlayerGui.introGui.title.Frame.Visible == true and StarterGui:GetCore("DevConsoleVisible") ~= true

			task.wait(1)

			VirtualInputManager:SendMouseButtonEvent(550, 520, 0, true, game, 1)
			task.wait()
			VirtualInputManager:SendMouseButtonEvent(550, 520, 0, false, game, 1)

			task.wait(3)
		end
	else
		Log("dev", "Auto Start", "Skipping Play Button")
	end

	-- Select Character
	if Workspace:FindFirstChild(Player.Name) == nil then
		-- Select Character
		if PlayerGui.CharacterSelection.Enabled then
			Remotes:WaitForChild("RemoteConfigConnection"):InvokeServer(unpack({
				[1] = "CharacterAltMultipliers",
			}))

			DataEvent:FireServer(unpack({
				[1] = {
					[1] = {
						[1] = "\1",
						[2] = {
							["\3"] = "select",
							["characterIndex"] = Config.LobbySettings.Miscellaneous.CharacterSelection,
						},
					},
					[2] = "L",
				},
			}))

			task.wait(5)
		end
	else
		Log("dev", "Auto Start", "Skipping Character Select")
	end

	-- Yield For Character
	repeat
		task.wait(1)
	until Workspace:FindFirstChild(Player.Name)

	-- Auto Add Stat Points
	if Config.LobbySettings.AutoStat.Enabled then
		local StatPoints = tonumber(PlayerGui.InventoryUi.Main.Display.Skills.Points.PointsLeft.PointsLeftLabel.Text)

		if StatPoints > 0 then
			local function SendEvent(stat: string, total: number)
				DataEvent:FireServer(unpack({
					[1] = {
						[1] = {
							[1] = "\1",
							[2] = { ["stat"] = stat, ["amount"] = total },
						},
						[2] = "0",
					},
				}))
			end

			if Config.LobbySettings.AutoStat.Class == "Warrior" then
				Log("dev", "Auto Stat", `Adding {Config.LobbySettings.AutoStat.Class} Stat Points`)
				SendEvent("physicalPower", StatPoints)
			elseif Config.LobbySettings.AutoStat.Class == "Mage" then
				Log("dev", "Auto Stat", `Adding {Config.LobbySettings.AutoStat.Class} Stat Points`)
				SendEvent("spellPower", StatPoints)
			else
				Log("dev", "Auto Stat", `Incorrect Class For Stat Points: {Config.LobbySettings.AutoStat.Class}`)
			end
		else
			Log("dev", "Auto Stat", "No Stat Points Available")
		end
	end

	-- Auto Collect Daily
	if Config.LobbySettings.Miscellaneous.CollectDailyReward then
		if PlayerGui.PlaytimeRewards.Main.Purchase.Claim.Visible == true then
			repeat
				DataEvent:FireServer(unpack({
					[1] = {
						[1] = {
							[1] = "\1",
							[2] = {
								["\3"] = "redeemReward",
							},
						},
						[2] = "\163",
					},
				}))
				task.wait(5)
			until PlayerGui.PlaytimeRewards.Main.Purchase.Claim.Visible ~= true
		else
			Log("dev", "Auto Daily", "Reward Is Not Ready")
		end
	end

	-- Auto Equip / Upgrade Gear
	if Config.LobbySettings.AutoEquipGear.Enabled then
		local Inventory = GetInventory()
		local Level = Player.leaderstats.Level.Value

		-- Auto Upgrade
		local function UpgradeItem(item, index, class, itemType)
			if Config.LobbySettings.AutoEquipGear.Upgrade then
				local Subbed = string.gsub(index, "%D", "")
				local Slot = tonumber(Subbed)

				if item.currentUpgrade ~= item.maxUpgrades then
					Log("dev", "Auto Upgrade", `Upgrading {item.name} With The Rarity Of {item.rarity}`)
					Remotes:WaitForChild("upgradeItem"):FireServer(unpack({
						[1] = itemType,
						[2] = Slot,
						[3] = class,
						[4] = item.maxUpgrades,
						[5] = "spendAll",
					}))
					task.wait(3)
				else
					Log("dev", "Auto Upgrade", `{item.name} With The Rarity Of {item.rarity} Is Already Maxed`)
				end
			end
		end

		for FolderName, ItemFolder in pairs(Inventory) do
			if FolderName == "weapons" then
				local Gold = Player.leaderstats.Gold.Value
				local BestWeapon, BestWeaponIndex, BestWeaponClass, BestWeaponDamage = nil, nil, nil, 0

				for index, Weapon in pairs(ItemFolder) do
					local UpgradeAmount = Weapon.maxUpgrades - Weapon.currentUpgrade

					if Config.LobbySettings.AutoEquipGear.Class == "Warrior" then
						if Weapon.levelReq <= Level and Weapon.physicalDamage > Weapon.spellPower then
							local Potential = CalculatePot(Weapon.physicalDamage, UpgradeAmount)
							local CanAfford = false

							if CalculateCost(Weapon.maxUpgrades, Weapon.currentUpgrade) < Gold then
								CanAfford = true
							end

							if
								Potential > BestWeaponDamage and CanAfford
								or BestWeaponDamage < Weapon.physicalDamage
							then
								BestWeaponDamage = Potential
								BestWeaponClass = "physical"
								BestWeaponIndex = index
								BestWeapon = Weapon
							end
						end
					elseif Config.LobbySettings.AutoEquipGear.Class == "Mage" then
						if Weapon.levelReq <= Level and Weapon.spellPower > Weapon.physicalDamage then
							local Potential = CalculatePot(Weapon.physicalDamage, UpgradeAmount)
							local CanAfford = false

							if CalculateCost(Weapon.maxUpgrades, Weapon.currentUpgrade) < Gold then
								CanAfford = true
							end

							if Potential > BestWeaponDamage and CanAfford or BestWeaponDamage < Weapon.spellPower then
								BestWeaponDamage = Potential
								BestWeaponClass = "spell"
								BestWeaponIndex = index
								BestWeapon = Weapon
							end
						end
					end
				end

				if BestWeapon ~= nil then
					if not BestWeapon.equipped then
						UpgradeItem(BestWeapon, BestWeaponIndex, BestWeaponClass, "weapon")

						Log("dev", "Auto Equip", `Equipping: {BestWeapon.name}`)
						DataEvent:FireServer(unpack({
							[1] = {
								[1] = {
									[1] = "\1",
									[2] = {
										["itemType"] = "weapon",
										["category"] = "weapons",
										["data"] = {
											["sellPrice"] = BestWeapon.sellPrice,
											["physicalDamage"] = BestWeapon.physicalDamage,
											["isSellable"] = BestWeapon.isSellable,
											["itemPotential"] = BestWeapon.itemPotential,
											["maxUpgrades"] = BestWeapon.maxUpgrades,
											["levelReq"] = BestWeapon.levelReq,
											["currentUpgrade"] = BestWeapon.currentUpgrade,
											["rarity"] = BestWeapon.rarity,
											["isTradeable"] = BestWeapon.isTradeable,
											["imageId"] = BestWeapon.imageId,
											["enchantment"] = BestWeapon.enchantment,
											["itemType"] = BestWeapon.itemType,
											["spellPower"] = BestWeapon.spellPower,
											["name"] = BestWeapon.name,
											["genericData"] = {
												["rarityStats"] = {
													["Legendary"] = {
														["LevelRequirement"] = BestWeapon.levelReq,
														["Upgrades"] = 2000000,
														["SpellPower"] = 750000000,
														["SellPrice"] = 400000000,
														["PhysicalPower"] = 5000,
													},
												},
												["attackSpeed"] = 1,
												["imageId"] = "rbxassetid://92824512863457",
												["class"] = Config.LobbySettings.AutoEquipGear.Class,
												["weaponType"] = "Staff",
												["name"] = BestWeapon.name,
											},
											["timestamp"] = BestWeapon.timestamp,
											["uniqueId"] = BestWeapon.uniqueId,
											["favorite"] = BestWeapon.favorite,
											["equipped"] = BestWeapon.equipped,
										},
										["equipped"] = false,
										["slot"] = "weapon",
									},
								},
								[2] = "\31",
							},
						}))
						task.wait(3)
					else
						Log("dev", "Auto Equip", `{BestWeapon.name} Is Already Equipped`)
					end
				end
			elseif FolderName == "helmets" then
				local Gold = Player.leaderstats.Gold.Value
				local BestHelmet, BestHelmetIndex, BestHelmetClass, BestHelmetDamage = nil, nil, nil, 0

				for index, Helmet in pairs(ItemFolder) do
					local UpgradeAmount = Helmet.maxUpgrades - Helmet.currentUpgrade

					if Config.LobbySettings.AutoEquipGear.Class == "Warrior" then
						if Helmet.levelReq <= Level and Helmet.physicalPower > Helmet.spellPower then
							local Potential = CalculatePot(Helmet.physicalPower, UpgradeAmount)
							local CanAfford = false

							if CalculateCost(Helmet.maxUpgrades, Helmet.currentUpgrade) < Gold then
								CanAfford = true
							end

							if
								Potential > BestHelmetDamage and CanAfford
								or BestHelmetDamage < Helmet.physicalPower
							then
								BestHelmetDamage = Potential
								BestHelmetClass = "physical"
								BestHelmetIndex = index
								BestHelmet = Helmet
							end
						end
					elseif Config.LobbySettings.AutoEquipGear.Class == "Mage" then
						if Helmet.levelReq <= Level and Helmet.spellPower > Helmet.physicalPower then
							local Potential = CalculatePot(Helmet.spellPower, UpgradeAmount)
							local CanAfford = false

							if CalculateCost(Helmet.maxUpgrades, Helmet.currentUpgrade) < Gold then
								CanAfford = true
							end

							if Potential > BestHelmetDamage and CanAfford or BestHelmetDamage < Helmet.spellPower then
								BestHelmetDamage = Potential
								BestHelmetClass = "spell"
								BestHelmetIndex = index
								BestHelmet = Helmet
							end
						end
					end
				end

				if BestHelmet ~= nil then
					if not BestHelmet.equipped then
						UpgradeItem(BestHelmet, BestHelmetIndex, BestHelmetClass, "helmet")

						Log("dev", "Auto Equip", `Equipping: {BestHelmet.name}`)
						DataEvent:FireServer(unpack({
							[1] = {
								[1] = {
									[1] = "\1",
									[2] = {
										["itemType"] = "helmet",
										["category"] = "helmets",
										["data"] = {
											["sellPrice"] = BestHelmet.sellPrice,
											["physicalPower"] = BestHelmet.physicalPower,
											["isSellable"] = BestHelmet.isSellable,
											["itemPotential"] = BestHelmet.itemPotential,
											["equipped"] = BestHelmet.equipped,
											["levelReq"] = BestHelmet.levelReq,
											["currentUpgrade"] = BestHelmet.currentUpgrade,
											["itemType"] = BestHelmet.itemType,
											["isTradeable"] = BestHelmet.isTradeable,
											["imageId"] = BestHelmet.imageId,
											["spellPower"] = BestHelmet.spellPower,
											["name"] = BestHelmet.name,
											["health"] = BestHelmet.health,
											["genericData"] = {
												["class"] = Config.LobbySettings.AutoEquipGear.Class,
												["rarityStats"] = {
													["Epic"] = {
														["LevelRequirement"] = BestHelmet.levelReq,
														["Upgrades"] = 650000,
														["Stamina"] = 2398000000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 59000000,
													},
													["Rare"] = {
														["LevelRequirement"] = BestHelmet.levelReq,
														["Upgrades"] = 617500,
														["Stamina"] = 2278100000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 56050000,
													},
													["Uncommon"] = {
														["LevelRequirement"] = ItemFolder.levelReq,
														["Upgrades"] = 585000,
														["Stamina"] = 2158200000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 53100000,
													},
													["Common"] = {
														["LevelRequirement"] = BestHelmet.levelReq,
														["Upgrades"] = 552500,
														["Stamina"] = 2038300000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 50150000,
													},
												},
												["imageId"] = BestHelmet.imageId,
												["name"] = BestHelmet.name,
											},
											["uniqueId"] = BestHelmet.uniqueId,
											["timestamp"] = BestHelmet.timestamp,
											["rarity"] = BestHelmet.rarity,
											["maxUpgrades"] = BestHelmet.maxUpgrades,
										},
										["equipped"] = false,
										["slot"] = "helmet",
									},
								},
								[2] = "\31",
							},
						}))
						task.wait(3)
					else
						Log("dev", "Auto Equip", `{BestHelmet.name} Is Already Equipped`)
					end
				end
			elseif FolderName == "chests" then
				local Gold = Player.leaderstats.Gold.Value
				local BestChest, BestChestIndex, BestChestClass, BestChestDamage = nil, nil, nil, 0

				for index, Chest in pairs(ItemFolder) do
					local UpgradeAmount = Chest.maxUpgrades - Chest.currentUpgrade

					if Config.LobbySettings.AutoEquipGear.Class == "Warrior" then
						if Chest.levelReq <= Level and Chest.physicalPower > Chest.spellPower then
							local Potential = CalculatePot(Chest.physicalPower, UpgradeAmount)
							local CanAfford = false

							if CalculateCost(Chest.maxUpgrades, Chest.currentUpgrade) < Gold then
								CanAfford = true
							end

							if Potential > BestChestDamage and CanAfford or BestChestDamage < Chest.physicalPower then
								BestChestDamage = Potential
								BestChestClass = "physical"
								BestChestIndex = index
								BestChest = Chest
							end
						end
					elseif Config.LobbySettings.AutoEquipGear.Class == "Mage" then
						if Chest.levelReq <= Level and Chest.spellPower > Chest.physicalPower then
							local Potential = CalculatePot(Chest.spellPower, UpgradeAmount)
							local CanAfford = false

							if CalculateCost(Chest.maxUpgrades, Chest.currentUpgrade) < Gold then
								CanAfford = true
							end

							if Potential > BestChestDamage and CanAfford or BestChestDamage < Chest.spellPower then
								BestChestDamage = Potential
								BestChestClass = "spell"
								BestChestIndex = index
								BestChest = Chest
							end
						end
					end
				end

				if BestChest ~= nil then
					if not BestChest.equipped then
						UpgradeItem(BestChest, BestChestIndex, BestChestClass, "chest")

						Log("dev", "Auto Equip", `Equipping: {BestChest.name}`)
						DataEvent:FireServer(unpack({
							[1] = {
								[1] = {
									[1] = "\1",
									[2] = {
										["itemType"] = "chest",
										["category"] = "chests",
										["data"] = {
											["sellPrice"] = BestChest.sellPrice,
											["physicalPower"] = BestChest.physicalPower,
											["isSellable"] = BestChest.isSellable,
											["itemPotential"] = BestChest.itemPotential,
											["equipped"] = BestChest.equipped,
											["levelReq"] = BestChest.levelReq,
											["currentUpgrade"] = BestChest.currentUpgrade,
											["itemType"] = BestChest.itemType,
											["isTradeable"] = BestChest.isTradeable,
											["imageId"] = BestChest.imageId,
											["spellPower"] = BestChest.spellPower,
											["name"] = BestChest.name,
											["health"] = BestChest.health,
											["genericData"] = {
												["class"] = Config.LobbySettings.AutoEquipGear.Class,
												["rarityStats"] = {
													["Epic"] = {
														["LevelRequirement"] = BestChest.levelReq,
														["Upgrades"] = 650000,
														["Stamina"] = 2398000000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 59000000,
													},
													["Rare"] = {
														["LevelRequirement"] = BestChest.levelReq,
														["Upgrades"] = 617500,
														["Stamina"] = 2278100000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 56050000,
													},
													["Uncommon"] = {
														["LevelRequirement"] = BestChest.levelReq,
														["Upgrades"] = 585000,
														["Stamina"] = 2158200000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 53100000,
													},
													["Common"] = {
														["LevelRequirement"] = BestChest.levelReq,
														["Upgrades"] = 552500,
														["Stamina"] = 2038300000,
														["SpellPower"] = 2000,
														["SellPrice"] = 300000000,
														["PhysicalPower"] = 50150000,
													},
												},
												["imageId"] = BestChest.imageId,
												["name"] = BestChest.name,
											},
											["uniqueId"] = BestChest.uniqueId,
											["timestamp"] = BestChest.timestamp,
											["rarity"] = BestChest.rarity,
											["maxUpgrades"] = BestChest.maxUpgrades,
										},
										["equipped"] = true,
										["slot"] = "chest",
									},
								},
								[2] = "\31",
							},
						}))
						task.wait(3)
					else
						Log("dev", "Auto Equip", `{BestChest.name} Is Already Equipped`)
					end
				end
			elseif FolderName == "abilities" and Config.LobbySettings.AutoEquipGear.EquipSpells then
				local EBestSpell, EBestSpellLevel = nil, 0
				local QBestSpell, QBestSpellLevel = nil, 0

				for index, Spell in pairs(ItemFolder) do
					local Description = Spell.description:lower()

					if Config.LobbySettings.AutoEquipGear.Class == "Warrior" then
						if
							Description:Find("physical")
							and Spell.levelReq > EBestSpellLevel
							and Spell.name ~= "skip"
						then
							EBestSpell = Spell
						end
					elseif Config.LobbySettings.AutoEquipGear.Class == "Mage" then
						if Description:Find("spell") and Spell.levelReq > EBestSpellLevel and Spell.name ~= "skip" then
							EBestSpell = Spell
						end
					end
				end

				if EBestSpell ~= nil and not EBestSpell.equipped.e and not EBestSpell.equipped.q then
					Log("dev", "Auto Equip", `Equipping: {EBestSpell.name} In The E Slot`)
					DataEvent:FireServer(unpack({
						[1] = {
							[1] = {
								[1] = "\1",
								[2] = {
									["itemType"] = "ability",
									["category"] = "abilities",
									["data"] = {
										["description"] = EBestSpell.description,
										["isTradeable"] = EBestSpell.isTradeable,
										["sellPrice"] = EBestSpell.sellPrice,
										["imageId"] = EBestSpell.imageId,
										["favorite"] = EBestSpell.favorite,
										["uniqueId"] = EBestSpell.uniqueId,
										["name"] = EBestSpell.name,
										["isSellable"] = EBestSpell.isSellable,
										["rarity"] = EBestSpell.rarity,
										["timestamp"] = EBestSpell.timestamp,
										["equipped"] = { ["q"] = EBestSpell.equipped.q, ["e"] = EBestSpell.equipped.e },
										["levelReq"] = EBestSpell.levelReq,
									},
									["equipped"] = EBestSpell.equipped,
									["slot"] = "e",
								},
							},
							[2] = '"',
						},
					}))
					EBestSpell.name = "skip"
					task.wait(3)
				end

				for index, Spell in pairs(ItemFolder) do
					local Description = Spell.description:lower()

					if Config.LobbySettings.AutoEquipGear.Class == "Warrior" then
						if
							Description:Find("physical")
							and Spell.levelReq > QBestSpellLevel
							and Spell.name ~= "skip"
						then
							QBestSpell = Spell
						end
					elseif Config.LobbySettings.AutoEquipGear.Class == "Mage" then
						if Description:Find("spell") and Spell.levelReq > EBestSpellLevel and Spell.name ~= "skip" then
							QBestSpell = Spell
						end
					end
				end

				if QBestSpell ~= nil and not QBestSpell.equipped.e and not QBestSpell.equipped.q then
					Log("dev", "Auto Equip", `Equipping: {QBestSpell.name} In The Q Slot`)
					DataEvent:FireServer(unpack({
						[1] = {
							[1] = {
								[1] = "\1",
								[2] = {
									["itemType"] = "ability",
									["category"] = "abilities",
									["data"] = {
										["description"] = QBestSpell.description,
										["isTradeable"] = QBestSpell.isTradeable,
										["sellPrice"] = QBestSpell.sellPrice,
										["imageId"] = QBestSpell.imageId,
										["favorite"] = QBestSpell.favorite,
										["uniqueId"] = QBestSpell.uniqueId,
										["name"] = QBestSpell.name,
										["isSellable"] = QBestSpell.isSellable,
										["rarity"] = QBestSpell.rarity,
										["timestamp"] = QBestSpell.timestamp,
										["equipped"] = { ["q"] = QBestSpell.equipped.q, ["e"] = QBestSpell.equipped.e },
										["levelReq"] = QBestSpell.levelReq,
									},
									["equipped"] = QBestSpell.equipped,
									["slot"] = "q",
								},
							},
							[2] = '"',
						},
					}))
					QBestSpell.name = "skip"
					task.wait(3)
				end
			end
		end
	end

	-- Auto Sell Gear
	if Config.LobbySettings.AutoSell.Enabled then
		local Inventory = GetInventory()
		local List = {}

		-- Check Item
		local function CheckItem(name, rare)
			local PassedKeepRarity, PassedKeepItems = nil, nil

			for KeepRarity, Value in pairs(Config.LobbySettings.AutoSell.KeepRarities) do
				if rare == KeepRarity then
					if Value == true then
						PassedKeepRarity = false
					else
						PassedKeepRarity = true
					end
				end
			end

			for ItemName, Rarities in pairs(Config.LobbySettings.AutoSell.KeepList) do
				if name == ItemName then
					for _, Rarity in pairs(Rarities) do
						if rare == Rarity then
							PassedKeepItems = false
						else
							PassedKeepItems = true
						end
					end
				else
					PassedKeepItems = true
				end
			end

			return PassedKeepItems, PassedKeepRarity
		end

		for FolderName, ItemFolder in pairs(Inventory) do
			if FolderName ~= "keys" and FolderName ~= "rings" and FolderName ~= "abilities" then
				for index, Item in pairs(ItemFolder) do
					if
						Item.equipped == false
						and Item.favorite ~= true
						and Item.isSellable == true
						and Item.levelReq < Config.LobbySettings.AutoSell.ItemLevelRequirement
					then
						local PassedItem, PassedRarity = CheckItem(Item.name, Item.rarity)
						if PassedItem == true and PassedRarity == true then
							local ItemTable = {
								[1] = {
									["chest"] = {},
									["helmet"] = {},
									["ability"] = {},
									["ring"] = {},
									["weapon"] = {},
								},
							}

							if FolderName == "weapons" then
								local Subbed = string.gsub(index, "%D", "")
								local Slot = tonumber(Subbed)

								if Config.LobbySettings.AutoSell.TestSell then
									Log("info", "Test Sell", `Name: {Item.name}`)
								else
									table.insert(ItemTable[1].weapon, Slot)
								end
							elseif FolderName == "helmets" then
								local Subbed = string.gsub(index, "%D", "")
								local Slot = tonumber(Subbed)

								if Config.LobbySettings.AutoSell.TestSell then
									Log("info", "Test Sell", `Name: {Item.name}`)
								else
									table.insert(ItemTable[1].helmet, Slot)
								end
							elseif FolderName == "chests" then
								local Subbed = string.gsub(index, "%D", "")
								local Slot = tonumber(Subbed)

								if Config.LobbySettings.AutoSell.TestSell then
									Log("info", "Test Sell", `Name: {Item.name}`)
								else
									table.insert(ItemTable[1].chest, Slot)
								end
							end
							Remotes:WaitForChild("sellItemEvent"):FireServer(unpack(ItemTable))
						end
					end
				end
			elseif FolderName == "abilities" then
				for index, Spell in pairs(ItemFolder) do
					if
						Spell.equipped.e == false
						and Spell.equipped.q == false
						and Spell.favorite ~= true
						and Spell.isSellable == true
						and Spell.levelReq < Config.LobbySettings.AutoSell.ItemLevelRequirement
					then
						local PassedSpell, PassedRarity = CheckItem(Spell.name, Spell.rarity)
						if PassedSpell == true and PassedRarity == true then
							if Config.LobbySettings.AutoSell.Keep2Spells then
								if List[Spell.name] then
									List[Spell.name] += 1
								else
									List[Spell.name] = 1
								end

								if List[Spell.name] > 2 then
									local Subbed = string.gsub(index, "%D", "")
									local Slot = tonumber(Subbed)

									if Config.LobbySettings.AutoSell.TestSell then
										Log("info", "Test Sell", `Name: {Spell.name}`)
									else
										Remotes:WaitForChild("sellItemEvent"):FireServer(unpack({
											[1] = {
												["chest"] = {},
												["helmet"] = {},
												["ability"] = {
													[1] = Slot,
												},
												["ring"] = {},
												["weapon"] = {},
											},
										}))
									end
								else
									Log("dev", "Auto Sell", `There Is Either 2 Or Less {Spell.name} Spells`)
								end
							else
								local Subbed = string.gsub(index, "%D", "")
								local Slot = tonumber(Subbed)

								if Config.LobbySettings.AutoSell.TestSell then
									Log("info", "Test Sell", `Name: {Spell.name}`)
								else
									Remotes:WaitForChild("sellItemEvent"):FireServer(unpack({
										[1] = {
											["chest"] = {},
											["helmet"] = {},
											["ability"] = {
												[1] = Slot,
											},
											["ring"] = {},
											["weapon"] = {},
										},
									}))
								end
							end
						end
					end
				end
			end
		end
	end

	-- Create / Join Dungeon Party
	if Config.LobbySettings.GameCreation.MultiFarm.Enabled then
		-- Finding The Host Account
		if Player.Name == Config.LobbySettings.GameCreation.MultiFarm.HostAccount then
			Log("dev", "Auto Party", `{Player.Name} Is The Host`)
			local JoinerAccountsTbl, MembersTbl, Mode = {}, {}, nil

			-- Setting The Joiner Accounts
			for _, name in pairs(Config.LobbySettings.GameCreation.MultiFarm.JoinerAccounts) do
				JoinerAccountsTbl[name] = true
			end

			-- Setting The Party Mode
			if Config.LobbySettings.GameCreation.DungeonSettings.Hardcore then
				Mode = "Hardcore"
			else
				Mode = "Normal"
			end

			-- Creating The Lobby
			DataEvent:FireServer(unpack({
				[1] = {
					[1] = {
						[1] = "\1",
						[2] = {
							["\3"] = "CreateParty",
							["partyData"] = {
								["difficulty"] = Config.LobbySettings.GameCreation.DungeonSettings.Difficulty,
								["minimumJoinLevel"] = 0,
								["tier"] = 1,
								["dungeonName"] = Config.LobbySettings.GameCreation.DungeonSettings.Dungeon,
								["mode"] = Mode,
								["visibility"] = "Private",
								["maxPlayers"] = 40,
							},
						},
					},
					[2] = "\158",
				},
			}))
			Log("dev", "Auto Party", `Created The Party`)

			-- Getting Party Requests
			DataEvent.OnClientEvent:Connect(function(data)
				for _, value in pairs(data) do
					for _, subValue in pairs(value) do
						local Requests = subValue.requests
						if Requests then
							Log("dev", "Auto Accept Requests", `Requests Was Not Nil`)
							for _, request in pairs(Requests) do
								local RequesterName = Players:GetNameFromUserIdAsync(request.requester_id)

								if JoinerAccountsTbl[RequesterName] then
									Log(
										"dev",
										"Auto Accept Requests",
										`Found {RequesterName} In The Joiner Accounts Table`
									)

									task.wait(2)

									DataEvent:FireServer(unpack({
										[1] = {
											[1] = {
												[1] = "\1",
												[2] = {
													["requestId"] = request.id,
													["\3"] = "HandleJoinRequest",
													["requestUsername"] = RequesterName,
													["requestAction"] = true,
												},
											},
											[2] = "\158",
										},
									}))
									table.insert(MembersTbl, RequesterName)
									Log("dev", "Auto Request", `Accepted {RequesterName} Join Request`)
								else
									Log(
										"dev",
										"Auto Accept Requests",
										`Did Not Find {RequesterName} In The Joiner Accounts Table`
									)
								end
							end
						else
							Log("dev", "Auto Accept Requests", "Requests Was Nil")
						end
					end
				end
			end)

			repeat
				task.wait()
			until #MembersTbl == #Config.LobbySettings.GameCreation.MultiFarm.JoinerAccounts

			-- Start Dungeon
			Log("dev", "Auto Party", "All The Members Have Joined")
		else
			Log("dev", "Auto Party", `{Player.Name} Is A Joiner`)

			DataEvent.OnClientEvent:Connect(function(data)
				for _, value in pairs(data) do
					for _, v in pairs(value) do
						local Party = v.party
						if Party then
							Log("dev", "Auto Request Party", "Party Was Not Nil")

							for a, b in pairs(Party.members) do
								print(a)
								for k, l in pairs(b) do
									print(k, l)
								end
							end

							task.wait(1)
							if
								string.find(Party.name, Config.LobbySettings.GameCreation.MultiFarm.HostAccount)
								and Party.dungeon == Config.LobbySettings.GameCreation.DungeonSettings.Dungeon
								and Party.difficulty == Config.LobbySettings.GameCreation.DungeonSettings.Difficulty
								and Party.visibility == "Private"
							then
								Log(
									"dev",
									"Auto Request Party",
									`Found {Config.LobbySettings.GameCreation.MultiFarm.HostAccount}'s Party`
								)

								task.wait(3)

								DataEvent:FireServer(unpack({
									[1] = {
										[1] = {
											[1] = "\1",
											[2] = {
												["\3"] = "RequestJoin",
												["partyId"] = Party.id,
											},
										},
										[2] = "\158",
									},
								}))
							else
								Log(
									"dev",
									"Auto Request Party",
									`Failed To Find {Config.LobbySettings.GameCreation.MultiFarm.HostAccount}'s Party`
								)
							end
						else
							Log("dev", "Auto Request Party", `Party Was Nil`)
						end
					end
				end
			end)
		end
	end

	Log("dev", "Script", "Finished Execution")
end
